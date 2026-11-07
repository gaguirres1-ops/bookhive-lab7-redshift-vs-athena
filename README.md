# Laboratorio 7: Redshift vs Athena - Proyecto Bookhive

## Descripci贸n del Proyecto
Este laboratorio realiza un an谩lisis comparativo de rendimiento y arquitectura entre Amazon Redshift y Amazon Athena utilizando el conjunto de datos de Bookhive.

## Integrantes del Equipo
* Aguirre Salda帽a, Glidis Lilani
* Clavijo Diaz, Cesar Joaquin
* Mauricio Rodriguez, Diego Sebastian
* Tarazona Aransaenz, Andrea Alejandra
* Vazquez Marquina, Yair Asael

## Estructura del Repositorio
* `datos/`: Conjuntos de datos locales y muestras para procesamiento.
* `infra/`: Plantillas de infraestructura (Athena y Redshift).
* `sql/`: Consultas SQL para creaci贸n de tablas y an谩lisis comparativo.
* `scripts/`: Scripts en Python/Boto3 para automatizaci贸n.
* `docs/`: Documentaci贸n del laboratorio y capturas de pantalla.
## Orden de ejecuci髇 (regi髇 us-east-2)
1. pip install boto3
2. python datos\generar_datos.py --sesiones 2000000 --usuarios 50000
3. terraform init y terraform apply en infra\datos, infra\athena e infra\redshift con -var sufijo=$sufijo (en Redshift definir $env:TF_VAR_admin_password)
4. python scripts\runner.py para cargar en Redshift y para el benchmark de Athena y Redshift con --rondas 3 --concurrencia 5

## Limpieza (en este orden)
1. terraform destroy de redshift
2. terraform destroy de athena
3. terraform destroy de datos
