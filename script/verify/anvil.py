"""Local Anvil transport, Foundry deployment and receipt checks for acceptance."""

import json
import os
import socket
import subprocess
import time
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from tempfile import TemporaryDirectory
from urllib.error import URLError
from urllib.request import ProxyHandler, Request, build_opener

ROOT = Path(__file__).resolve().parents[2]
ROLES = ("admin", "treasury", "lp1", "lp2", "borrower1", "borrower2", "liquidator", "payer", "recipient", "subscriber")
HTTP = build_opener(ProxyHandler({}))


def check(description, actual, expected):
    if actual != expected:
        raise ValueError(f"{description}: expected {expected!r}, got {actual!r}")
    return actual


def command(*args, **kwargs):
    return subprocess.run(
        args, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace",
        check=True, timeout=120, **kwargs,
    ).stdout.strip()


class Node:
    def __init__(self, url):
        self.url = url

    def rpc(self, method, *params):
        payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
        request = Request(self.url, data=payload, headers={"Content-Type": "application/json"})
        with HTTP.open(request, timeout=10) as response:
            result = json.load(response)
        if "error" in result:
            raise RuntimeError(f"{method}: {result['error']}")
        return result["result"]

    def timestamp(self):
        return int(self.rpc("eth_getBlockByNumber", "latest", False)["timestamp"], 16)


@contextmanager
def fresh_node():
    with socket.socket() as port_selector:
        port_selector.bind(("127.0.0.1", 0))
        port = port_selector.getsockname()[1]
    node = Node(f"http://127.0.0.1:{port}")
    process = subprocess.Popen(
        ["anvil", "--host", "127.0.0.1", "--port", str(port), "--chain-id", "31337",
         "--hardfork", "cancun", "--gas-limit", "30000000", "--order", "fifo", "--quiet"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
    )
    try:
        deadline = time.monotonic() + 15
        while process.poll() is None and time.monotonic() < deadline:
            try:
                check("fresh chain", node.rpc("eth_blockNumber"), "0x0")
                break
            except (URLError, ConnectionError):
                time.sleep(0.1)
        else:
            raise RuntimeError(f"Anvil did not start on port {port}")
        yield node
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


class Contract:
    """These acceptance calls only use static ABI words (addresses, booleans and integers)."""
    def __init__(self, name, address, node):
        self.address = address
        self.node = node
        artifact = json.loads((ROOT / "out" / f"{name}.sol" / f"{name}.json").read_text(encoding="utf-8"))
        self.methods = artifact["methodIdentifiers"]
        self.compiler = artifact["metadata"]["compiler"]["version"]

    def data(self, name, args):
        candidates = [selector for sig, selector in self.methods.items() if sig.partition("(")[0] == name]
        if len(candidates) != 1:
            raise ValueError(f"Expected one ABI selector for {name}, found {len(candidates)}")
        words = [int(value, 16) if isinstance(value, str) else value for value in args]
        return "0x" + candidates[0] + "".join(f"{number:064x}" for number in words)

    def read(self, name, *args):
        data = self.node.rpc("eth_call", {"to": self.address, "data": self.data(name, args)}, "latest")[2:]
        if len(data) == 0 or len(data) % 64 != 0:
            raise ValueError(f"Invalid static return data for {name}: {data}")
        words = tuple(int(data[i:i + 64], 16) for i in range(0, len(data), 64))
        return words[0] if len(words) == 1 else words


@dataclass(frozen=True)
class Transaction:
    actor: str
    contract: Contract
    method: str
    args: tuple


class Market:
    def __init__(self, node, report):
        self.node = node
        self.report = report
        self.roles = dict(zip(ROLES, node.rpc("eth_accounts"), strict=True))
        report["roles"] = self.roles
        report["chainId"] = int(node.rpc("eth_chainId"), 16)
        check("Anvil chain ID", report["chainId"], 31337)
        with TemporaryDirectory() as temp:
            command(
                "forge", "script", "script/deploy/Deploy.s.sol:DeployVeyra", "--sig", "run(address,address)",
                self.roles["admin"], self.roles["treasury"], "--rpc-url", node.url,
                "--unlocked", "--sender", self.roles["admin"], "--broadcast", "--slow", "--non-interactive",
                env=dict(os.environ, FOUNDRY_BROADCAST=temp),
            )
            deployment = json.loads(next(Path(temp).rglob("run-latest.json")).read_text(encoding="utf-8"))
        addresses = {}
        report["deploymentReceipts"] = []
        for tx in deployment["transactions"]:
            receipt = node.rpc("eth_getTransactionReceipt", tx["hash"])
            check("deployment transaction", receipt["status"], "0x1")
            report["deploymentReceipts"].append(receipt)
            if receipt["contractAddress"]:
                addresses[tx["contractName"]] = receipt["contractAddress"]
        self.usd = Contract("MockUSD", addresses["MockUSD"], node)
        self.eth = Contract("MockETH", addresses["MockETH"], node)
        self.protocol = Contract("Veyra", addresses["Veyra"], node)
        report["contracts"] = addresses
        report["solc"] = self.protocol.compiler
        node.rpc("evm_setAutomine", False)

    def tx(self, actor, method, *args, contract=None):
        return Transaction(actor, contract or self.protocol, method, args)

    def mine(self, *transactions, timestamp=None, record=True):
        """Submit in FIFO order and require every receipt to have that exact block and index."""
        hashes = []
        for tx in transactions:
            hashes.append(self.node.rpc("eth_sendTransaction", {
                "from": self.roles[tx.actor], "to": tx.contract.address,
                "data": tx.contract.data(tx.method, tx.args), "gas": hex(700_000),
            }))
        target = timestamp if timestamp is not None else self.node.timestamp() + 1
        self.node.rpc("evm_setNextBlockTimestamp", target)
        self.node.rpc("evm_mine")
        block = self.node.rpc("eth_getBlockByNumber", "latest", False)
        check("block timestamp", int(block["timestamp"], 16), target)
        check("block inclusion and order", block["transactions"], hashes)
        for index, (tx, tx_hash) in enumerate(zip(transactions, hashes, strict=True)):
            receipt = self.node.rpc("eth_getTransactionReceipt", tx_hash)
            if record:
                self.report["transactions"].append({
                    "actor": tx.actor, "method": tx.method, "args": tx.args, "timestamp": target, "receipt": receipt,
                })
            check(f"{tx.actor}.{tx.method} status ({tx_hash})", receipt["status"], "0x1")
            check("receipt block", receipt["blockHash"], block["hash"])
            check("receipt index", int(receipt["transactionIndex"], 16), index)
        return target

    def fund(self, entries):
        transactions = []
        for role, token, amount in entries:
            transactions.extend([
                self.tx("admin", "mint", self.roles[role], amount, contract=token),
                self.tx(role, "approve", self.protocol.address, amount, contract=token),
                self.tx(role, "deposit", token.address, amount),
            ])
        self.mine(*transactions)

    def claim(self, label, actual, expected):
        check(label, actual, expected)
        self.report["checks"][label] = actual
