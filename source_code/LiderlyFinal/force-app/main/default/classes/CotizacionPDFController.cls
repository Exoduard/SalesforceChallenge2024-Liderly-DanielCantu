public class CotizacionPDFController {
    public Cotizacion_Academica__c cotizacion { get; set; }
    public List<FechaPago> fechasPago { get; set; }
    
    public class FechaPago {
        public String concepto { get; set; }
        public Date fecha { get; set; }
        public Decimal monto { get; set; }
    }
    
    public CotizacionPDFController(ApexPages.StandardController stdController) {
        this.cotizacion = (Cotizacion_Academica__c)stdController.getRecord();
        
        // Consulta completa de la cotización con todos los campos necesarios
        try {
            this.cotizacion = [
                SELECT Id, Name, 
                       Estudiante__r.Name, 
                       Estudiante__r.Nombre_Estudiante__c,
                       Estudiante__r.Apellidos__c,
                       Estudiante__r.CorreoEstudiante__c,
                       Sede__c, 
                       Cantidad_Materias__c, 
                       Forma_de_Pago__c,
                       Subtotal_Sin_Descuentos__c, 
                       Total_Descuento_por_Becas__c,
					   Descuento_Por_Cantidad__c,
                	   Descuento_de_Contado__c,
                       Descuento_Total_Porcentaje__c, 
                       Total_Final__c,
                       Beca_Excelencia__c, 
                       Beca_Deportiva__c,
                       Beca_Familiar_Docente__c, 
                       Beca_Necesidad_Economica__c,
                	   Subtotal_con_Descuento_por_Cantidad__c,
					   Coordinador_Carrera__c,          // ID del Coordinador
           			   Coordinador_Carrera__r.Name,     // Nombre del Coordinador
           			   Coordinador_Carrera__r.Email 
                FROM Cotizacion_Academica__c
                WHERE Id = :cotizacion.Id
                LIMIT 1
            ];
            
            calcularFechasPago();
        } catch (QueryException e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Error al cargar la cotización: ' + e.getMessage()
            ));
        }
    }
    
    private void calcularFechasPago() {
        fechasPago = new List<FechaPago>();
        Integer currentYear = System.today().year();
        
        // Pago de inscripción
        FechaPago inscripcion = new FechaPago();
        inscripcion.concepto = 'Inscripción';
        inscripcion.fecha = Date.newInstance(currentYear, 7, 10);
        
        if(cotizacion.Forma_de_Pago__c == 'Contado') {
            inscripcion.monto = cotizacion.Total_Final__c;
            fechasPago.add(inscripcion);
        } else {
            // Calcular monto mensual
            Decimal montoMensual = cotizacion.Total_Final__c / 6; // 1 inscripción + 5 mensualidades
            inscripcion.monto = montoMensual;
            fechasPago.add(inscripcion);
            
            // Agregar mensualidades
            for(Integer i = 8; i <= 12; i++) {
                FechaPago mensualidad = new FechaPago();
                mensualidad.concepto = 'Mensualidad ' + (i-7);
                mensualidad.fecha = Date.newInstance(currentYear, i, 10);
                mensualidad.monto = montoMensual;
                fechasPago.add(mensualidad);
            }
        }
    }
}