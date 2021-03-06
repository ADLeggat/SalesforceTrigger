public with sharing class TriggerHandler {
    List<System.TriggerOperation> triggerOperations = new List<System.TriggerOperation>();
    private String sObjectName;
    private static List<String> triggerIgnore = new List<String>();

    @TestVisible private List<Trigger_Class__mdt> triggerClasses {
        get {
            if(triggerClasses == null) {
                triggerClasses = getTriggerClasses();
            }
            return triggerClasses;
        }
        set;
    }

    private List<Trigger_Class__mdt> getTriggerClasses() {
        if(triggerMeta != null) {
            triggerClasses = [
                SELECT Id, Class_Name__c, Is_Active__c, Sort_Order__c
                FROM Trigger_Class__mdt 
                WHERE Trigger__c = :triggerMeta.Id
                ORDER BY Sort_Order__c ASC
            ];
        }
        return triggerClasses;
    }

    @TestVisible private Trigger__mdt triggerMeta {
        get {
            if(triggerMeta == null) {
                triggerMeta = Trigger__mdt.getInstance(sObjectName);
            }
            return triggerMeta;
        }
        set;
    }
    
    public TriggerHandler(String sObjectName) {
        this.sObjectName = sObjectName;
    }

    public static void addTriggerIgnore(String triggerName) {
        triggerIgnore.add(triggerName);
    }

    public void run() {
        if(triggerIgnore.contains(sObjectName) || !triggerMeta.Is_Active__c || !Trigger.isExecuting) {
            return;
        }

        executeTriggerClasses();
    }

    @TestVisible private void executeTriggerClasses() {
        for(Trigger_Class__mdt triggerClassMeta: triggerClasses) {
            if(triggerClassMeta.Is_Active__c) {
                ITrigger triggerClass = getClassInstance(triggerClassMeta.Class_Name__c);
                triggerOperations.addAll(triggerClass.setTriggerOperations());
                
                execute(triggerClass);
            }
        }
    }

    @TestVisible private ITrigger getClassInstance(String className) {
        Type t = Type.forName(className);

        if(t == null) {
            throw new TypeException('No class found');
        }

        Object triggerClass = t.newInstance();
        if (!(triggerClass instanceof ITrigger)) {
            throw new TypeException('Trigger class must implement ITrigger');
        } 
        return (ITrigger) triggerClass;
    }

    @TestVisible private void execute(ITrigger triggerClass) {
        if(triggerOperations.size() == 0) {
            throw new ListException('At least one trigger operation must be set');
        }

        for(System.TriggerOperation triggerOperation: triggerOperations) {

            if(Trigger.operationType != null && triggerOperation != Trigger.operationType) {
                continue;
            }

            switch on triggerOperation {
                when BEFORE_INSERT, AFTER_INSERT, AFTER_UNDELETE  {
                    triggerClass.execute(Trigger.newMap, null);
                }
                when BEFORE_UPDATE, AFTER_UPDATE {
                    triggerClass.execute(Trigger.newMap, Trigger.oldMap);
                }
                when BEFORE_DELETE, AFTER_DELETE {
                    triggerClass.execute(null, Trigger.oldMap);
                }
            }
        }
    }
}
