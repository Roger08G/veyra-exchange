# Cómo trabajar en Veyra

Estas instrucciones se aplican a todo el repositorio. Trabaja en español, de forma directa y realista. Veyra v0.1.0 simula en Anvil un protocolo DeFi con cuentas, pagos y préstamos con garantía. El objetivo es poder seguir cada operación desde el movimiento de tokens hasta su efecto en saldos, deuda, participaciones e ingresos.

## Antes de cambiar algo

- Lee el [alcance del MVP](./README.md) y las [convenciones de GitHub](./AGENTS/github.md). Esta última guía define los encabezados de commit, las ramas por versión y la relación entre release y tag. Aplícala cuando la tarea incluya esas operaciones. Si el usuario pide trabajar sin Git, respeta ese límite también al verificar los cambios.
- Busca la operación en la [especificación económica](./docs/economic.md). Allí están los parámetros de referencia y los enlaces a las ocho fichas EC-01 a EC-08. Lee la ficha afectada y las de las partidas que también cambian. Por ejemplo, una apertura usa las condiciones de EC-03, la caja de EC-04, la garantía y la deuda de EC-05, y el ingreso de EC-08.
- Inspecciona los contratos en `src/`, las pruebas en `test/` y los scripts en `script/` para saber qué existe. `Counter` es el ejemplo inicial de Foundry. Para afirmar que una función de Veyra está implementada, identifica su entrada real y la prueba que la ejercita.

## Al implementar o documentar una operación

1. Identifica quién puede ejecutarla, el token y sus unidades, el origen de los fondos y su destino. MockUSD tiene 6 decimales y MockETH tiene 18. Consulta las [reglas de tokens](./docs/tokens.md) y los [permisos y límites de confianza](./docs/security.md).
2. Usa las fórmulas de la ficha al instante de ejecución. Respeta la desigualdad exacta del umbral, el sentido del redondeo y las condiciones fijadas al abrir cada préstamo. Toma los valores de referencia de la especificación económica.
3. Comprueba el estado antes y después por token. La custodia debe conciliar los disponibles, la garantía bloqueada, la caja del fondo, los ingresos retenidos y los excedentes directos. Cuando intervengan varias cadenas, sus cambios y eventos deben confirmarse o revertirse juntos.
4. Conserva la estructura de las fichas y los identificadores existentes. Cita la cadena junto a cada invariante o caso, por ejemplo `EC-01 / INV-03 / CL-04`, porque la numeración se repite entre cadenas. Si dos reglas dan resultados distintos para el mismo estado, señala ambas y el efecto concreto. Un cambio de comportamiento económico debe quedar explícito en la ficha y en sus pruebas.

## Cómo verificar y entregar

Para cambios de Solidity, ejecuta las siguientes comprobaciones desde la raíz. [Configuración de CI](./.github/workflows/test.yml)

```sh
forge fmt --check
forge build --sizes
forge test -vvv
```

Vincula las pruebas de la operación con las propiedades que comprueban. Para cambios que conecten varias cadenas, usa los [escenarios de aceptación](./docs/tests.md) y el [procedimiento de despliegue local](./docs/deploy.md) cuando estén implementados los recorridos correspondientes. En cambios exclusivamente documentales, comprueba los enlaces, las referencias y las cifras afectadas.

Al entregar, indica qué cambió, qué comprobación ejecutaste y qué resultado obtuviste. Distingue una cifra recalculada, una prueba de Forge y una transacción observada en Anvil.
