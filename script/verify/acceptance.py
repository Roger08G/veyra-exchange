"""Deploy the MVP and replay both published scenarios twice using real Anvil transactions."""

import json
import subprocess
from hashlib import sha256

from anvil import ROOT, Market, check, command, fresh_node

USD = 10**6
ETH = 10**18
DAY = 86_400
OUTPUT = ROOT / "cache" / "acceptance"


def verify_deployment(market):
    p, roles = market.protocol, market.roles
    contracts = market.report["contracts"]
    check("three deployment addresses", len(set(contracts.values())), 3)
    market.report["runtimeSha256"] = {
        name: sha256(bytes.fromhex(market.node.rpc("eth_getCode", address, "latest")[2:])).hexdigest()
        for name, address in contracts.items()
    }
    for name, address in (("admin", roles["admin"]), ("treasury", roles["treasury"]),
                          ("usd", market.usd.address), ("eth", market.eth.address)):
        check(name, p.read(name), int(address, 16))
    for token, decimals in ((market.usd, 6), (market.eth, 18)):
        check("token decimals", token.read("decimals"), decimals)
        check("enabled asset", p.read("enabled", token.address), 1)
        check("initial custody", token.read("balanceOf", p.address), 0)
    market.claim("market parameters", p.read("parameters"), (10 * USD, 30 * DAY, 3600, 6000, 7500, 500))
    market.claim("basic terms", p.read("planTerms", False), (10, 20, 100, 800))
    market.claim("paid terms", p.read("planTerms", True), (5, 5, 50, 500))
    market.claim("initial price", p.read("price"), 2000 * USD)
    price_receipt = market.report["deploymentReceipts"][-1]
    price_block = market.node.rpc("eth_getBlockByHash", price_receipt["blockHash"], False)
    check("price timestamp", p.read("priceUpdatedAt"), int(price_block["timestamp"], 16))
    for name in ("cash", "equity", "totalShares", "activeLoanCount", "totalCollateral"):
        market.claim(f"initial {name}", p.read(name), 0)


def liquidation_event(market, loan_id, expected):
    entry = next(tx for tx in reversed(market.report["transactions"]) if tx["method"] == "liquidate")
    topic = command("cast", "keccak", "Liquidated(uint256,address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)")
    logs = [log for log in entry["receipt"]["logs"]
            if log["address"].lower() == market.protocol.address.lower() and log["topics"][0] == topic]
    check("single liquidation event", len(logs), 1)
    topics = [int(value, 16) for value in logs[0]["topics"][1:]]
    check("liquidation position and counterparties", topics,
          [loan_id, int(market.roles["liquidator"], 16), int(market.roles["borrower2"], 16)])
    raw = logs[0]["data"][2:]
    words = tuple(int(raw[i:i + 64], 16) for i in range(0, len(raw), 64))
    market.claim("liquidation debt, repaid, interest, principal, loss, seized, returned, execution price", words, expected)


def principal_scenario(m):
    p, usd, eth, roles = m.protocol, m.usd, m.eth, m.roles
    m.fund([("lp1", usd, 5000 * USD), ("lp2", usd, 5000 * USD), ("payer", usd, 100 * USD),
            ("subscriber", usd, 10 * USD), ("borrower1", usd, 70 * USD), ("liquidator", usd, 600 * USD),
            ("borrower1", eth, ETH), ("borrower2", eth, ETH)])
    start_plan = m.mine(m.tx("lp1", "supply", 5000 * USD), m.tx("lp2", "supply", 5000 * USD),
                        m.tx("payer", "pay", roles["recipient"], 100 * USD), m.tx("subscriber", "subscribe"))
    for lp in ("lp1", "lp2"):
        m.claim(f"initial shares of {lp}", p.read("sharesOf", roles[lp]), 5000 * USD)
    m.claim("individual payment net", p.read("available", roles["recipient"], usd.address), 99_800_000)
    m.claim("subscription and payment revenue", p.read("retained", usd.address), 10_200_000)
    expiry = start_plan + 30 * DAY
    check("subscription active", p.read("plan", roles["subscriber"]), (1, expiry))

    opened = m.mine(m.tx("borrower1", "openLoan", 1000 * USD, ETH), m.tx("borrower2", "openLoan", 1000 * USD, ETH))
    first_id, second_id = (p.read("activeLoan", roles[name]) for name in ("borrower1", "borrower2"))
    check("different loan IDs", first_id != second_id and first_id > 0 and second_id > 0, True)
    for account, loan_id, balance in (("borrower1", first_id, 1060), ("borrower2", second_id, 990)):
        data = p.read("loan", loan_id)
        check("opened loan", data, (int(roles[account], 16), 1, 1000 * USD, 0, 1000 * USD, 0, opened, 800, 100, ETH))
        m.claim(f"disbursed balance of {account}", p.read("available", roles[account], usd.address), balance * USD)
    m.claim("cash after opening", p.read("cash"), 8000 * USD)
    m.claim("retained after openings", p.read("retained", usd.address), 30_200_000)
    m.mine(timestamp=expiry)
    check("plan at expiry", p.read("plan", roles["subscriber"]), (0, expiry))

    m.mine(m.tx("borrower1", "repay", first_id, 540 * USD), timestamp=opened + 365 * DAY // 2)
    m.claim("first principal, interest and debt after partial pay", p.read("loan", first_id)[2:5], (500 * USD, 0, 500 * USD))

    final_time = opened + 365 * DAY
    pay_and_update = [m.tx("borrower1", "repay", first_id, 520 * USD), m.tx("admin", "publishPrice", 630 * USD)]
    # Observe the prefix at exactly the liquidation timestamp, then replay it in the final canonical block.
    snapshot = m.node.rpc("evm_snapshot")
    m.mine(*pay_and_update, timestamp=final_time, record=False)
    m.claim("debt before loss", p.read("loan", second_id)[4], 1080 * USD)
    m.claim("equity before loss", p.read("equity"), 10_140 * USD)
    check("restore prefix snapshot", m.node.rpc("evm_revert", snapshot), True)
    m.mine(*pay_and_update, m.tx("liquidator", "liquidate", second_id), timestamp=final_time)
    liquidation_event(m, second_id, (1080 * USD, 600 * USD, 80 * USD, 520 * USD, 480 * USD, ETH, 0, 630 * USD))
    for loan_id, state in ((first_id, 2), (second_id, 3)):
        check("closed position", p.read("loan", loan_id)[1:5], (state, 0, 0, 0))
    m.claim("cash after loss", p.read("cash"), 9660 * USD)
    m.claim("equity after loss", p.read("equity"), 9660 * USD)
    m.claim("outstanding shares after loss", p.read("totalShares"), 10_000 * USD)
    m.mine(m.tx("lp1", "redeem", 5000 * USD), m.tx("lp2", "redeem", 5000 * USD))

    withdrawals = [("lp1", usd, 4830 * USD, 4_825_170_000), ("lp2", usd, 4830 * USD, 4_825_170_000),
                   ("borrower2", usd, 990 * USD, 989_010_000), ("recipient", usd, 99_800_000, 99_700_200),
                   ("borrower1", eth, ETH, 999 * ETH // 1000), ("liquidator", eth, ETH, 999 * ETH // 1000)]
    for role, token, gross, _ in withdrawals:
        m.claim(f"withdrawable {role}:{'USD' if token is usd else 'ETH'}", p.read("available", roles[role], token.address), gross)
    m.claim("custody USD before withdrawals", usd.read("balanceOf", p.address), 10_780 * USD)
    m.claim("custody ETH before withdrawals", eth.read("balanceOf", p.address), 2 * ETH)
    m.mine(m.tx("treasury", "withdrawRevenue", usd.address, 30_200_000))
    m.mine(*(m.tx(role, "withdraw", token.address, gross) for role, token, gross, _ in withdrawals))
    for role, token, _, net in withdrawals:
        m.claim(f"external {role}:{'USD' if token is usd else 'ETH'}", token.read("balanceOf", roles[role]), net)
    for token, fees in ((usd, 10_749_800), (eth, 2 * ETH // 1000)):
        m.claim(f"withdrawal fees {'USD' if token is usd else 'ETH'}", p.read("retained", token.address), fees)
    m.mine(m.tx("treasury", "withdrawRevenue", usd.address, 10_749_800),
           m.tx("treasury", "withdrawRevenue", eth.address, 2 * ETH // 1000))
    for token, label in ((usd, "USD"), (eth, "ETH")):
        m.claim(f"final custody {label}", token.read("balanceOf", p.address), 0)
        m.claim(f"final available {label}", p.read("totalAvailable", token.address), 0)
        m.claim(f"final retained {label}", p.read("retained", token.address), 0)
        for account in roles.values():
            check(f"individual {label} balance", p.read("available", account, token.address), 0)
    m.claim("treasury USD collected", usd.read("balanceOf", roles["treasury"]), 40_949_800)
    m.claim("treasury ETH collected", eth.read("balanceOf", roles["treasury"]), 2 * ETH // 1000)
    for name in ("cash", "equity", "activeLoanCount", "totalShares", "totalCollateral"):
        m.claim(f"final {name}", p.read(name), 0)


def surplus_scenario(m):
    usd, eth, p, roles = m.usd, m.eth, m.protocol, m.roles
    m.fund([("lp1", usd, 1600 * USD), ("liquidator", usd, 1600 * USD), ("borrower2", eth, ETH)])
    m.mine(m.tx("lp1", "supply", 1600 * USD), m.tx("admin", "publishPrice", 3000 * USD))
    # The first position in a fresh instance has ID 1. The receipt binds that ID to the same-block close.
    m.mine(m.tx("borrower2", "openLoan", 1600 * USD, ETH), m.tx("admin", "publishPrice", 2000 * USD),
           m.tx("liquidator", "liquidate", 1))
    seized, returned = 84 * ETH // 100, 16 * ETH // 100
    liquidation_event(m, 1, (1600 * USD, 1600 * USD, 0, 1600 * USD, 0, seized, returned, 2000 * USD))
    m.claim("borrower net disbursement", p.read("available", roles["borrower2"], usd.address), 1584 * USD)
    m.claim("opening fee retained", p.read("retained", usd.address), 16 * USD)
    m.claim("borrower collateral returned", p.read("available", roles["borrower2"], eth.address), returned)
    m.claim("liquidator collateral received", p.read("available", roles["liquidator"], eth.address), seized)
    m.claim("cash after liquidation", p.read("cash"), 1600 * USD)
    m.claim("equity after liquidation", p.read("equity"), 1600 * USD)
    m.claim("locked collateral", p.read("totalCollateral"), 0)
    m.claim("active loans", p.read("activeLoanCount"), 0)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    versions = {name: command(name, "--version").splitlines()[0] for name in ("forge", "cast", "anvil")}
    versions["commit"] = command("git", "rev-parse", "HEAD")
    versions["dirtyWorkingTree"] = bool(command("git", "status", "--porcelain"))
    for name, scenario in (("principal", principal_scenario), ("sobrante", surplus_scenario)):
        economic_reference = None
        for run in (1, 2):
            report = dict(versions, scenario=name, run=run, transactions=[], checks={}, passed=False)
            try:
                with fresh_node() as node:
                    market = Market(node, report)
                    verify_deployment(market)
                    scenario(market)
                if economic_reference is None:
                    economic_reference = report["checks"]
                else:
                    check("repeated economic results", report["checks"], economic_reference)
                report["passed"] = True
                print(f"{name} {run}/2: {len(report['transactions'])} market/setup transactions, {len(report['checks'])} checks")
            except subprocess.CalledProcessError as exc:
                report["error"] = (exc.stderr or exc.stdout or str(exc)).strip()
                raise RuntimeError(report["error"]) from exc
            except Exception as exc:
                report["error"] = str(exc)
                raise
            finally:
                (OUTPUT / f"{name}-{run}.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Acceptance passed. Receipts, addresses, versions, gas and checks: {OUTPUT}")


if __name__ == "__main__":
    main()
