@isTest
private class CotizacionAcademicaTriggerTest {
    @TestSetup
    static void setupTestData() {
        // Create test coordinator user
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User coordinador = new User(
            Username = 'coord1@test1.com',
            Alias = 'coord1',
            Email = 'coord1@test1.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Coordinator1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId.Id,
            TimeZoneSidKey = 'America/Mexico_City'
        );
        insert coordinador;
        
        // Create approver user
        User approver = new User(
            Username = 'approver1@test1.com',
            Alias = 'aprv1',
            Email = 'approver1@test1.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Approver1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId.Id,
            TimeZoneSidKey = 'America/Mexico_City'
        );
        insert approver;
        
        // Asignar conjunto de permisos al aprobador si existe
        List<PermissionSet> ps = [SELECT Id FROM PermissionSet WHERE Name = 'Aprobador_Cotizaciones' LIMIT 1];
        if (!ps.isEmpty()) {
            insert new PermissionSetAssignment(
                AssigneeId = approver.Id,
                PermissionSetId = ps[0].Id
            );
        }
        
        System.runAs(approver) {
            // Crear estudiante de prueba
            Estudiante__c estudiante = new Estudiante__c(
                Nombre_Estudiante__c = 'Test',
                Apellidos__c = 'Student',
                CorreoEstudiante__c = 'test1@test1.com',
                Estado__c = 'Prospecto',
                Fecha_Nacimiento__c = Date.today().addYears(-20),
                Promedio__c = 9.5
            );
            insert estudiante;
            
            // Crear oportunidad de prueba
            Opportunity oportunidad = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = System.today().addMonths(1)
            );
            insert oportunidad;
        }
    }
    
    @isTest
    static void testTriggerOnStatusChange() {
        // Obtener datos de prueba
        User approver = [SELECT Id FROM User WHERE Username = 'approver1@test1.com' LIMIT 1];
        User coordinador = [SELECT Id FROM User WHERE Username = 'coord1@test1.com' LIMIT 1];
        Estudiante__c estudiante = [SELECT Id FROM Estudiante__c WHERE CorreoEstudiante__c = 'test1@test1.com' LIMIT 1];
        Opportunity oportunidad = [SELECT Id FROM Opportunity LIMIT 1];
        
        System.runAs(approver) {
            // Crear cotización en estado borrador
            Cotizacion_Academica__c cotizacion = new Cotizacion_Academica__c(
                Estudiante__c = estudiante.Id,
                Opportunity__c = oportunidad.Id,
                Sede__c = 'Jalisco',
                Cantidad_Materias__c = 5,
                Forma_de_Pago__c = 'Mensualidades',
                Estado_Cotizacion__c = 'Borrador',
                Coordinador_Carrera__c = coordinador.Id
            );
            
            Test.startTest();
            // Insertar cotización
            insert cotizacion;
            
            // Simular proceso de aprobación
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Enviando para aprobación.');
            req.setObjectId(cotizacion.Id);
            req.setSubmitterId(UserInfo.getUserId());
            Approval.ProcessResult result = Approval.process(req);
            
            // Si la solicitud fue enviada exitosamente
            if(result.isSuccess()) {
                // Aprobar el registro
                Approval.ProcessWorkitemRequest appReq = new Approval.ProcessWorkitemRequest();
                appReq.setComments('Aprobado.');
                appReq.setAction('Approve');
                appReq.setNextApproverIds(new List<Id>{UserInfo.getUserId()});
                
                // Obtener el ID del elemento de trabajo
                List<Id> newWorkItemIds = result.getNewWorkitemIds();
                appReq.setWorkitemId(newWorkItemIds.get(0));
                
                // Procesar la aprobación
                Approval.ProcessResult appResult = Approval.process(appReq);
                
                // Actualizar el estado de la cotización
                if(appResult.isSuccess()) {
                    cotizacion.Estado_Cotizacion__c = 'Aprobada';
                    update cotizacion;
                }
            }
            
            Test.stopTest();
            
            // Verificar que la cotización fue procesada
            List<AsyncApexJob> jobsEncolados = [
                SELECT Id, Status, MethodName 
                FROM AsyncApexJob 
                WHERE ApexClass.Name = 'CotizacionEmailService'
            ];
            System.assertNotEquals(0, jobsEncolados.size(), 'Debería haber un job encolado para enviar el email');
        }
    }
}