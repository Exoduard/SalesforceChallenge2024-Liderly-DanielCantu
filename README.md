# Sistema de Cotizaciones Universidad Learning Force 🎓

## Descripción
Sistema integral desarrollado en Salesforce para automatizar el proceso de cotización y gestión de descuentos para estudiantes universitarios. Permite manejar múltiples sedes, diferentes tipos de becas y genera cotizaciones en PDF con envío automático por correo electrónico.

## 🌟 Características Principales

### Gestión de Cotizaciones
- Cálculo automático de costos por sede
- Sistema de descuentos por cantidad de materias
- Gestión de múltiples tipos de becas
- Proceso de aprobación automatizado
- Generación y envío de PDF

### Sedes y Costos por materia

### Sistema de Descuentos

## 🛠️ Tecnologías Utilizadas
- Salesforce Apex
- Visualforce
- Process Builder
- Apex Email Services
- Custom Objects & Fields
- Validation Rules
- Approval Processes

## 📁 Estructura del Proyecto

### Objetos Personalizados
- `Estudiante__c`
- `Cotizacion_Academica__c`

### Clases Apex Principales
- `CotizacionEmailService.cls`: Maneja el envío de correos
- `CotizacionPDFController.cls`: Controla la generación de PDFs
- `CotizacionAcademicaTrigger.cls`: Trigger para automatizaciones

### Páginas Visualforce
- `CotizacionPDF.page`: Template para generación de PDF

## 🧪 Tests
El proyecto incluye pruebas como:
```apex
@isTest
private class CotizacionEmailServiceTest {
    // Pruebas unitarias para el servicio de email
}

@isTest
private class CotizacionAcademicaTriggerTest {
    // Pruebas para el trigger
}
```

## 💡 Lecciones Aprendidas y Mejoras Futuras
- Maximizar el uso de objetos estándar de Salesforce
- Optimizar para mejor escalabilidad
- Considerar límites del gobernador en el diseño
- Implementar más reportes y dashboards
- Mejorar la integración con sistemas externos

## 📈 Resultados
- Automatización completa del proceso de cotización
- Reducción significativa en tiempo de procesamiento
- Mayor precisión en cálculos
- Mejor experiencia de usuario

## ✉️ Contacto
Daniel Eduardo Cantu Moreno
- LinkedIn: https://www.linkedin.com/in/danielecm/
---
*Desarrollado como parte del Reto Final Liderly*

