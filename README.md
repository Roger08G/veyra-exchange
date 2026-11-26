<p align="center">
    <img src="./images/logo.png" alt="Logo de Veyra" width="190">
</p>

<h1 align="center">🪙 Veyra Exchange</h1>

<p align="center">
    💰 Veyra es una plataforma financiera que integra cuentas, pagos y préstamos con garantía 💰
</p>

Veyra es una plataforma financiera basada en contratos inteligentes EVM que integra cuentas, pagos y préstamos con garantía. Gestiona los fondos, las deudas, las comisiones y las pérdidas mediante reglas económicas explícitas.

## Alcance del MVP — `v0.1.0`

- **Entorno:** despliegue local en Anvil, con precios simulados y configurables para valorar las garantías.
- **Activos:** MockUSD (6 decimales) para pagos, cuotas, liquidez y deuda. MockETH (18 decimales) sirve de garantía. Las cuentas admiten depósitos y retiradas de ambos.
- **Mercado:** un único mercado de préstamos y un único fondo de liquidez.
- **Cuentas:** depósitos y retiradas, manteniendo los saldos disponibles para pagos separados del capital aportado al fondo de liquidez.
- **Pagos:** transferencias individuales entre cuentas, con comisiones según el plan vigente del emisor y registro de cada operación.
- **Planes:** un plan básico y uno de pago. El plan de pago tendrá duración fija, caducidad y renovación manual.
- **Liquidez:** aportaciones al fondo a cambio de participaciones y retiradas según el valor de estas y la liquidez disponible.
- **Préstamos:** un máximo de un préstamo activo por cuenta, respaldado por una garantía bloqueada y limitado por su valor. La tasa de interés y la comisión de apertura quedarán fijadas al abrirlo, según el plan vigente.
- **Intereses y devolución:** interés simple sobre el principal pendiente, devoluciones parciales o totales y liberación de la garantía restante al saldar la deuda.
- **Liquidaciones y pérdidas:** liquidación de posiciones que incumplan el umbral de garantía. La deuda incobrable reducirá el patrimonio del fondo y el valor de sus participaciones.
- **Ingresos del protocolo:** contabilización y retirada de comisiones y cuotas ya cobradas, separadas de los saldos de las cuentas y del patrimonio del fondo.

## Economía

El primer hito es un despliegue reproducible en Anvil. En la misma instancia deben cuadrar un pago interno, una suscripción, una aportación y su reembolso, un préstamo devuelto, otro liquidado con pérdida y las retiradas externas de usuarios y tesorería. Las ocho fichas especifican las reglas y el plan de pruebas fija los resultados esperados.

> [Cadenas económicas y configuración de referencia](./docs/economic.md) · [Tokens](./docs/tokens.md)

## Arquitectura

La [arquitectura de integración del MVP](./docs/arquitectura.md) define la custodia común, las interfaces, el estado que gestiona cada módulo y el orden de implementación.

## Despliegue

> [Despliegue local en Anvil](./docs/deploy.md)

## Tests y Validación

> [Plan de pruebas y escenario de aceptación](./docs/tests.md)

## Seguridad

> [Custodia, permisos y supuestos de seguridad](./docs/security.md)

## Licencia

[LICENSE](./LICENSE)
