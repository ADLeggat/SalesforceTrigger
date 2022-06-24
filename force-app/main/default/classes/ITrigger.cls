public interface ITrigger {
    
    List<System.TriggerOperation> setTriggerOperations();
    void execute(Map<Id, SObject> newMap, Map<Id, SObject> oldMap);
}
