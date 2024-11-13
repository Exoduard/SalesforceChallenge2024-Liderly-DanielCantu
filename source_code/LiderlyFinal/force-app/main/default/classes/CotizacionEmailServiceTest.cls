@isTest
private class CotizacionEmailServiceTest {
    @TestSetup
    static void setupTestData() {
        // Create test coordinator user - crear coordinador de prueba
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User coordinador = new User(
            Username = 'coordinador1@test1.com',
            Alias = 'coord1',
            Email = 'coordinador1@test1.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Coordinator1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId.Id,
            TimeZoneSidKey = 'America/Mexico_City'
        );
        insert coordinador;
        
        // Create test approver user - Crear usuario aprovador de prueba
        User testUser = new User(
            Username = 'approver1@test1.com',
            Alias = 'aprob1',
            Email = 'approver1@test1.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Approver1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId.Id,
            TimeZoneSidKey = 'America/Mexico_City',
            IsActive = true
        );
        insert testUser;
        
        System.runAs(testUser) {
            // Create test students with different scenarios - Crear estudiantes de prueba con diferentes escenarios...
            List<Estudiante__c> estudiantes = new List<Estudiante__c>();
            
            // Student with valid email - estudiante con correo no repetido
            estudiantes.add(new Estudiante__c(
                Nombre_Estudiante__c = 'Test Valid1',
                Apellidos__c = 'Email Student1',
                CorreoEstudiante__c = 'valid1@test1.com',
                Estado__c = 'Prospecto',
                Fecha_Nacimiento__c = Date.today().addYears(-20),
                Promedio__c = 9.5
            ));
            
            // Student with different email - Otro estudainte con correo diferente
            estudiantes.add(new Estudiante__c(
                Nombre_Estudiante__c = 'Test Invalid1',
                Apellidos__c = 'Invalid Email1',
                CorreoEstudiante__c = 'invalid1@test1.com',
                Estado__c = 'Prospecto',
                Fecha_Nacimiento__c = Date.today().addYears(-20),
                Promedio__c = 8.0
            ));
            
            insert estudiantes;
            
            // Create test opportunities - Crear oportunidades de prueba 
            List<Opportunity> oportunidades = new List<Opportunity>();
            for(Integer i = 0; i < 2; i++) {
                oportunidades.add(new Opportunity(
                    Name = 'Test Opportunity ' + i,
                    StageName = 'Prospecting',
                    CloseDate = System.today().addMonths(1)
                ));
            }
            insert oportunidades;
        }
    }
    
    
    
    @isTest
    static void testContadoPaymentSchedule() {
        // Retrieve data from users - Recuperar datos de usuarios
        User testUser = [SELECT Id FROM User WHERE Username = 'approver1@test1.com' LIMIT 1];
        User coordinador = [SELECT Id FROM User WHERE Username = 'coordinador1@test1.com' LIMIT 1];
        Estudiante__c estudiante = [SELECT Id FROM Estudiante__c WHERE CorreoEstudiante__c = 'valid1@test1.com' LIMIT 1];
        Opportunity oportunidad = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest(); 
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Creates a new Cotizacion_Academica__c record with "Contado" (one-time payment)
            Cotizacion_Academica__c cotizacion = new Cotizacion_Academica__c(
                Estudiante__c = estudiante.Id,
                Opportunity__c = oportunidad.Id,
                Sede__c = 'Jalisco',
                Cantidad_Materias__c = 5,
                Forma_de_Pago__c = 'Contado',
                Estado_Cotizacion__c = 'Borrador',
                Coordinador_Carrera__c = coordinador.Id
            );
            insert cotizacion;
            // Set the page context and initialize the controller
            Test.setCurrentPage(Page.CotizacionPDF);
            ApexPages.StandardController sc = new ApexPages.StandardController(cotizacion);
            CotizacionPDFController controller = new CotizacionPDFController(sc);
            // Verify that there is only 1 payment for "Contado" payment type
            System.assertEquals(1, controller.fechasPago.size(), 'Contado should have single payment');
        }
        Test.stopTest();
    }
    
    // Same structure, but used to verifiy 6 payments in the quote -- Misma estructura que el codigo pasado, pero se utiliza para revisar que se registren 6 pagos.
    
    @isTest
    static void testMensualidadesPaymentSchedule() {
		// Retrieve data from users - Recuperar datos de usuarios
        User testUser = [SELECT Id FROM User WHERE Username = 'approver1@test1.com' LIMIT 1];
        User coordinador = [SELECT Id FROM User WHERE Username = 'coordinador1@test1.com' LIMIT 1];
        Estudiante__c estudiante = [SELECT Id FROM Estudiante__c WHERE CorreoEstudiante__c = 'valid1@test1.com' LIMIT 1];
        Opportunity oportunidad = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
        // Creates a new Cotizacion_Academica__c record with "Mensualidades" (monthly payments)
            Cotizacion_Academica__c cotizacion = new Cotizacion_Academica__c(
                Estudiante__c = estudiante.Id,
                Opportunity__c = oportunidad.Id,
                Sede__c = 'Jalisco',
                Cantidad_Materias__c = 5,
                Forma_de_Pago__c = 'Mensualidades',
                Estado_Cotizacion__c = 'Borrador',
                Coordinador_Carrera__c = coordinador.Id
            );
            insert cotizacion;
		// Set the page context and initialize the controller
            Test.setCurrentPage(Page.CotizacionPDF);
            ApexPages.StandardController sc = new ApexPages.StandardController(cotizacion);
            CotizacionPDFController controller = new CotizacionPDFController(sc);
		// Verify that there are 6 payments for "Mensualidades" payment type
            System.assertEquals(6, controller.fechasPago.size(), 'Mensualidades should have 6 payments');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidQuoteLoad() {
        Test.startTest();
        
        // Crear datos necesarios, gracias a las validation rules que puse...
        User coordinador = [SELECT Id FROM User WHERE Username = 'coordinador1@test1.com' LIMIT 1];
        Estudiante__c estudiante = [SELECT Id FROM Estudiante__c WHERE CorreoEstudiante__c = 'valid1@test1.com' LIMIT 1];
        Opportunity oportunidad = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Crear una cotización válida primero
        Cotizacion_Academica__c cotizacionValida = new Cotizacion_Academica__c(
            Estudiante__c = estudiante.Id,
            Opportunity__c = oportunidad.Id,
            Sede__c = 'Jalisco',
            Cantidad_Materias__c = 5,
            Forma_de_Pago__c = 'Mensualidades',
            Estado_Cotizacion__c = 'Borrador',
            Coordinador_Carrera__c = coordinador.Id
        );
        insert cotizacionValida;
        
        // Probar carga exitosa primero
        ApexPages.StandardController scValido = new ApexPages.StandardController(cotizacionValida);
        CotizacionPDFController controllerValido = new CotizacionPDFController(scValido);
        System.assertNotEquals(null, controllerValido.cotizacion, 'Cotización válida debería cargarse');
        
        // Ahora probar con una cotización inválida
        Cotizacion_Academica__c cotizacionInvalida = new Cotizacion_Academica__c();
        ApexPages.StandardController scInvalido = new ApexPages.StandardController(cotizacionInvalida);
        CotizacionPDFController controllerInvalido = new CotizacionPDFController(scInvalido);
        
        // Verificar mensajes de error
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertNotEquals(0, messages.size(), 'Debería haber mensajes de error');
        
        Boolean tieneErrorEsperado = false;
        for(ApexPages.Message msg : messages) {
            if(msg.getSeverity() == ApexPages.Severity.ERROR) {
                tieneErrorEsperado = true;
                break;
            }
        }
        System.assert(tieneErrorEsperado, 'Debería haber un mensaje de error');
        
        Test.stopTest();
    }
    
    
    
    // Clase Mock para respuestas HTTP, esto sirve para probar el controlador de PDF, si no no entra el test...
    // Mock class made to create HTTP responses, without this, the CotizacionPDFController wont be tested...
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true}');
            res.setStatusCode(200);
            return res;
        }
    } 
}