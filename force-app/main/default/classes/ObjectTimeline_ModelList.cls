public with sharing class ObjectTimeline_ModelList {
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public String id { get; set; }
    @AuraEnabled
    public List<ObjectTimeline_Model> models { get; set; }

    public ObjectTimeline_ModelList(String id, String name, List<ObjectTimeline_Model> models, Boolean descending) {
        this.id = id;
        this.name = name;

        for (ObjectTimeline_Model model : models) {
            model.descending = descending;
        }

        models.sort();

        this.models = models;
    }
}
