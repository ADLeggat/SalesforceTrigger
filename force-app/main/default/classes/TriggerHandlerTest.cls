@IsTest
public with sharing class TriggerHandlerTest {
    private static final String SOBJECT_TYPE = 'Account';
    private static Boolean testRunWasSuccessful = false;
    private static Integer triggerEventsConsumed = 0;

    @IsTest
    static void noClassFound() {
        Exception caughtException;

        Test.startTest();
        try {
            Trigger_Class__mdt triggerClassMetadata = buildTriggerClassMetadata('ClassDoesntExist');

            TriggerHandler handler = new TriggerHandler(SOBJECT_TYPE);
            handler.triggerClasses = new List<Trigger_Class__mdt> {
                triggerClassMetadata
            };
            handler.getClassInstance(triggerClassMetadata.Class_Name__c);
        } catch(Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'Exception is caught');
        System.assertEquals('No class found', caughtException.getMessage(), 'Exception message');
        System.assert(caughtException instanceof TypeException);
    }

    @IsTest
    static void classDoesntImplementITriggerInterface() {
        Exception caughtException;

        Test.startTest();
        try {
            Trigger_Class__mdt triggerClassMetadata = buildTriggerClassMetadata(ClassWithoutInterface.class.getName());

            TriggerHandler handler = new TriggerHandler(SOBJECT_TYPE);
            handler.triggerClasses = new List<Trigger_Class__mdt> {
                triggerClassMetadata
            };
            handler.getClassInstance(triggerClassMetadata.Class_Name__c);
        } catch(Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'Exception is caught');
        System.assertEquals('Trigger class must implement ITrigger', caughtException.getMessage(), 'Exception message');
        System.assert(caughtException instanceof TypeException);
    }

    @IsTest
    static void noTriggerOperationsSet() {
        Exception caughtException;

        Test.startTest();
        try {
            Trigger_Class__mdt triggerClassMetadata = buildTriggerClassMetadata(
                ClassWithoutTriggerOperations.class.getName()
            );

            TriggerHandler handler = new TriggerHandler(SOBJECT_TYPE);
            handler.triggerClasses = new List<Trigger_Class__mdt> {
                triggerClassMetadata
            };
            handler.execute(new ClassWithoutTriggerOperations());
        } catch(Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'Exception is caught');
        System.assertEquals('At least one trigger operation must be set', caughtException.getMessage(), 'Exception message');
        System.assert(caughtException instanceof ListException);
    }

    @IsTest
    static void run() {
        Trigger_Class__mdt triggerClassMetadata = buildTriggerClassMetadata(
            ClassWithTriggerOperations.class.getName()
        );

        Test.startTest();
        TriggerHandler handler = new TriggerHandler(SOBJECT_TYPE);
        handler.triggerClasses = new List<Trigger_Class__mdt> {
            triggerClassMetadata
        };
        handler.executeTriggerClasses();
        Test.stopTest();

        System.assertEquals(true, testRunWasSuccessful, 'Trigger class execution was successful');
        System.assertEquals(3, triggerEventsConsumed, 'Three trigger events consumed');
    }

    @IsTest
    static void triggerIgnore() {
        TriggerHandler.addTriggerIgnore(SOBJECT_TYPE);

        Trigger_Class__mdt triggerClassMetadata = buildTriggerClassMetadata(
            ClassWithTriggerOperations.class.getName()
        );

        Test.startTest();
        TriggerHandler handler = new TriggerHandler(SOBJECT_TYPE);
        handler.triggerClasses = new List<Trigger_Class__mdt> {
            triggerClassMetadata
        };
        handler.run();
        Test.stopTest();

        System.assertEquals(false, testRunWasSuccessful, 'Trigger was ignored');
    }

    @IsTest
    static void triggerClassInactive() {
        TriggerHandler.addTriggerIgnore(SOBJECT_TYPE);

        Trigger_Class__mdt triggerClassMetadata = buildTriggerClassMetadata(
            ClassWithTriggerOperations.class.getName()
        );
        triggerClassMetadata.Is_Active__c = false;

        Test.startTest();
        TriggerHandler handler = new TriggerHandler(SOBJECT_TYPE);
        handler.triggerClasses = new List<Trigger_Class__mdt> {
            triggerClassMetadata
        };
        handler.run();
        Test.stopTest();

        System.assertEquals(false, testRunWasSuccessful, 'Trigger class inactive');
    }

    static Trigger_Class__mdt buildTriggerClassMetadata(String className) {

        Trigger_Class__mdt triggerClassMetadata = new Trigger_Class__mdt(
            Class_Name__c = className,
            Is_Active__c = true,
            Sort_Order__c = 0
        );

        return triggerClassMetadata;
    }

    public class ClassWithoutInterface { }

    public class ClassWithoutTriggerOperations implements ITrigger {
        public List<System.TriggerOperation> setTriggerOperations() {
            return new List<System.TriggerOperation>();
        }

        public void execute(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {}
    }

    public class ClassWithTriggerOperations implements ITrigger {
        public List<System.TriggerOperation> setTriggerOperations() {
            return new List<System.TriggerOperation> {
                System.TriggerOperation.BEFORE_INSERT,
                System.TriggerOperation.BEFORE_UPDATE,
                System.TriggerOperation.BEFORE_DELETE
            };
        }

        public void execute(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
            testRunWasSuccessful = true;
            triggerEventsConsumed += 1;
        }
    }
}
