# Despliegue local

Veyra v0.1.0 se despliega en Anvil con identificador de cadena 31337. El [script de Foundry](../script/deploy/Deploy.s.sol) crea MockUSD, MockETH y la custodia, asigna la emisión de los mocks al administrador y publica el precio inicial de 2 000 MockUSD por MockETH. La tesorería tiene una dirección distinta. Los tokens empiezan con suministro cero. [Configuración económica](./economic.md)

## Reproducir la aceptación completa

Desde la raíz del repositorio, con Foundry v1.8.3 (Forge, Cast y Anvil en el PATH), Python 3.10 o superior y el submódulo `lib/forge-std` disponible, ejecutar:

```sh
python script/verify/acceptance.py
```

El [ejecutor de aceptación](../script/verify/acceptance.py) arranca cuatro instancias independientes en puertos locales libres, utiliza el mismo script de despliegue en cada una y las cierra al terminar. Repite el [escenario principal y la liquidación con sobrante](./tests.md) dos veces cada uno. Usa la biblioteca estándar de Python y las cuentas desbloqueadas del nodo. Forge compila con la versión de Solidity y el perfil EVM de [foundry.toml](../foundry.toml).

- Verifica en cadena direcciones, roles, configuración de planes y mercado, decimales, activos habilitados, primer precio y estado inicial. La cuenta administradora emite los tokens de prueba en las carteras de los actores. Cada titular autoriza y deposita desde la suya.
- Desactiva la minería automática después del despliegue. Coloca las operaciones simultáneas en una cola FIFO, mina el bloque y verifica el tiempo y el índice de cada recibo. Para observar el patrimonio justo antes de la liquidación con pérdida, toma una instantánea temporal, ejecuta la devolución y el cambio de precio, lee el patrimonio, recupera la instantánea y confirma el bloque completo con la liquidación.
- Compara los resultados con los importes esperados en unidades mínimas y con la repetición del mismo escenario. El proceso devuelve un código de error ante una desviación.

Los informes locales se guardan en `cache/acceptance/principal-{1,2}.json` y `cache/acceptance/sobrante-{1,2}.json`. Cada uno contiene el commit y si había trabajo pendiente, versiones, direcciones y huellas del bytecode desplegado, comprobaciones y recibos completos. Los recibos identifican el bloque, la transacción, el gas y los eventos reales de cada paso. El campo `passed` indica si terminó correctamente.

## Desplegar una instancia para uso interactivo

Para conservar una instancia y operar sobre ella, iniciar Anvil en una terminal:

```sh
anvil --host 127.0.0.1 --port 8545 --chain-id 31337 --hardfork cancun
```

En una segunda terminal, desde la raíz de Veyra, este comando usa las direcciones públicas de las dos primeras cuentas de Anvil con su configuración por defecto. La primera será administradora y la segunda será tesorería. Si se configuraron otras cuentas, consultar `cast rpc eth_accounts --rpc-url http://127.0.0.1:8545` y sustituir las direcciones.

```sh
forge script script/deploy/Deploy.s.sol:DeployVeyra --sig "run(address,address)" 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 --rpc-url http://127.0.0.1:8545 --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 --unlocked --broadcast --slow
```

Forge registra las direcciones de creación y los recibos en `broadcast/Deploy.s.sol/31337/run-latest.json`. Se puede verificar el mercado con `cast call DIRECCION_DE_VEYRA "price()(uint256)" --rpc-url http://127.0.0.1:8545`. El entero esperado es 2 000 000 000. Esta instancia permanece disponible mientras siga funcionando el proceso de Anvil.

## Entrega continua en Anvil

El [workflow de GitHub Actions](../.github/workflows/test.yml) utiliza permisos globales vacíos y concede lectura de contenido por trabajo. Las acciones se fijan por revisión, Foundry por versión y forge-std por el commit del submódulo. El checkout descarta las credenciales y las cuentas que firman las transacciones son las de Anvil local.

| Ejecución | Validación | Evidencia |
| --- | --- | --- |
| Pull request, push a `main` o ejecución manual | Comprueba formato, compilación y tamaños. Verifica el descubrimiento de las siete suites, ejecuta Forge con semilla fija y obtiene un informe de gas de las pruebas de rendimiento. | Inventario de pruebas y gas asociados al commit. |
| Tras superar la validación en `main` o en una ejecución manual | Ejecuta el mismo comando de aceptación local en un runner aislado. Un fallo en despliegue, recibos o conciliación hace fallar el trabajo. | Cuatro informes de aceptación si la ejecución termina. Si una ejecución falla, se conservan los informes alcanzados y el diagnóstico disponible. |

La publicación de una versión estable es un paso explícito conforme a las [convenciones del proyecto](../AGENTS/github.md).
