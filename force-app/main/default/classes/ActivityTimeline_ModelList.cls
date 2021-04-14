public with sharing class ActivityTimeline_ModelList {
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public String id { get; set; }
    @AuraEnabled
    public List<ActivityTimeline_Model> models { get; set; }

    public ActivityTimeline_ModelList(String id, String name, List<ActivityTimeline_Model> models, Boolean descending) {
        this.id = id;
        this.name = name;

        for (ActivityTimeline_Model model : models) {
            model.descending = descending;
        }

        models.sort();

        this.models = models;
    }
}
