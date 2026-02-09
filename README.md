# task_manager

Para probar el flujo completo sin crear cuentas nuevas, puedes usar las siguientes credenciales:
Rol
Jefe@gmail.com
Pass: 3002537976
Empleado@gmail.com
Pass: 3002537976
Visita el proyecto aqui: https://task-manager-portfolio-a6877.web.app/

Nota: También puedes registrar nuevos usuarios directamente desde la pantalla de inicio. El sistema te permite elegir el rol durante el registro.

Un sistema integral de gestión de tareas desarrollado con Flutter y Firebase, optimizado para la supervisión de equipos mediante flujos de trabajo basados en evidencias y una arquitectura de almacenamiento de costo cero

Descripción
Este proyecto resuelve el problema de la supervisión remota y la gestión de evidencias. A diferencia de otros gestores, integra una arquitectura híbrida que utiliza Firebase para la lógica de datos y Cloudinary para el almacenamiento masivo de imágenes, asegurando que la aplicación se mantenga dentro de los límites gratuitos incluso con un alto volumen de usuarios.

Stack Tecnológico
Frontend: Flutter 3.x (Multiplataforma: Web, Android, iOS).

Base de Datos: Cloud Firestore (NoSQL en tiempo real).

Autenticación: Firebase Auth.

Media Management: Cloudinary API (REST).

Gestión de Estado: Provider (Arquitectura reactiva).

Características Principales
Sistema de Roles (RBAC)
Jefe (Admin): Crear tareas, asignar prioridades, anclar tareas críticas, aprobar o rechazar trabajos y visualizar reportes.

Empleado: Visualizar tareas asignadas, registrar logs de progreso y subir evidencias fotográficas del trabajo terminado.

Gestión de Evidencia Inteligente
Captura de fotos directa desde la app.

Subida asíncrona a Cloudinary procesada por bytes (Uint8List) para compatibilidad total con Flutter Web.

Visor de imágenes interactivo con soporte para Zoom (InteractiveViewer) y pantalla completa.

Lógica de Reportes y Negocio
Reporte Individual: Solo incluye tareas con estado completada y isDone: true.

Reporte Mensual/Semanal: Filtrado dinámico por fechas y estados de aprobación.

Priorización: Niveles de prioridad (Baja, Media, Alta) y sistema de "Pins" para tareas urgentes.

Instalación y Uso
Pre-requisitos
Tener instalado Flutter.

Configurar un proyecto en Firebase.

Obtener credenciales de Cloudinary.

Configuración
Clonar el repositorio:

git clone https://github.com/tu-usuario/task_manager.git

Instalar dependencias:

flutter pub get

Configurar tus credenciales en lib/services/cloudinary_service.dart:

final String cloudName = "tu_cloud_name";
final String uploadPreset = "tu_preset_unsigned";

Guía de Uso del Sistema
1. Creación de Tarea (Flujo del Jefe)
El jefe completa el formulario asignando un título, descripción, fecha de entrega y prioridad. La tarea aparece instantáneamente en el panel del empleado asignado gracias a los Streams de Firebase.

Ejecución y Evidencia (Flujo del Empleado)
El empleado abre la tarea y puede:

Añadir comentarios o dudas.

Subir una foto de la labor realizada presionando el botón "Subir Evidencia".

Una vez subida la foto, la tarea cambia automáticamente a estado "En Revisión".

3. Aprobación o Rechazo (Cierre de Ciclo)
El jefe revisa la foto (puede hacer zoom para ver detalles).

Si aprueba: La tarea pasa a completada y se contabiliza para el reporte del mes.

Si rechaza: La tarea vuelve a estado pendiente, se marca isDone: false y se le notifica al empleado el motivo del rechazo en el log de progreso.

Mejoras Futuras (Escalabilidad)
Para transformar este MVP en una solución de nivel empresarial (SaaS), se han identificado las siguientes líneas de evolución técnica:

1. Sistema de Notificaciones Push 
Objetivo: Implementar Firebase Cloud Messaging (FCM) para alertar a los empleados sobre nuevas tareas asignadas y notificar al jefe cuando una evidencia ha sido subida, eliminando la necesidad de revisar la app constantemente.

2. Generación Automatizada de Reportes (PDF/Excel) 
Objetivo: Integrar un motor de reportes que compile todas las tareas con estado completada del mes y genere un documento descargable listo para auditoría o nómina, aplicando las reglas de negocio establecidas para el empleado del mes.

3. Modo Offline con Sincronización Diferida 
Objetivo: Utilizar Hive o SQLite para persistencia local. Esto permitiría a los empleados registrar avances y tomar fotos en zonas sin cobertura de internet, sincronizando automáticamente con Firebase y Cloudinary en cuanto se recupere la conexión.

4. Geolocalización de Evidencias 
Objetivo: Adjuntar metadatos de ubicación GPS a las fotos subidas mediante Cloudinary. Esto proporcionaría al jefe una capa extra de seguridad para verificar que el trabajo fue realizado en el sitio correspondiente.

5. Dashboard Analítico para el Jefe 
Objetivo: Crear una vista de estadísticas con gráficos (usando fl_chart) para visualizar el tiempo promedio de resolución de tareas, tasa de rechazo y comparativa de rendimiento entre empleados.
