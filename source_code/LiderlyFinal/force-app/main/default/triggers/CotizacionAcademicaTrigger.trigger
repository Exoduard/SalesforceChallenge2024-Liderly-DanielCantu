trigger CotizacionAcademicaTrigger on Cotizacion_Academica__c (after update) {
    System.debug('Trigger ejecutado');
    if (Trigger.isAfter && Trigger.isUpdate) {
        Set<Id> cotizacionesParaEnviar = new Set<Id>();
        
        for (Cotizacion_Academica__c cotizacion : Trigger.new) {
            Cotizacion_Academica__c oldCotizacion = Trigger.oldMap.get(cotizacion.Id);
            
            System.debug('Estado anterior: ' + oldCotizacion.Estado_Cotizacion__c);
            System.debug('Estado nuevo: ' + cotizacion.Estado_Cotizacion__c);
            
            // Verificar si el estado cambió a "Aprobada"
            if (cotizacion.Estado_Cotizacion__c == 'Aprobada' && oldCotizacion.Estado_Cotizacion__c != 'Aprobada') {
                System.debug('Cotización marcada para envío: ' + cotizacion.Id);
                cotizacionesParaEnviar.add(cotizacion.Id);
            }
        }
        
        // Llamar al método asíncrono solo si hay cotizaciones aprobadas
        if (!cotizacionesParaEnviar.isEmpty()) {
            System.debug('Enviando correos para las cotizaciones: ' + cotizacionesParaEnviar);
            CotizacionEmailService.processCotizacionesAsync(cotizacionesParaEnviar);
        }
    }
}