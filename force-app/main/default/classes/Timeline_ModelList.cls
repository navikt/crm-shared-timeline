public with sharing class Timeline_ModelList {
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public String id { get; set; }
    @AuraEnabled
    public List<Timeline_Model> models { get; set; }

    public Timeline_ModelList(String id, String name, List<Timeline_Model> models, Boolean descending) {
        this.id = id;
        this.name = name;

        for (Timeline_Model model : models) {
            model.descending = descending;
        }

        models.sort();

        this.models = models;
    }
}
