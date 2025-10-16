CREATE TABLE `sap-iac-test.bw2bq_migrate_dev.Object_Master` (
  Object_ID STRING NOT NULL OPTIONS(description="Unique identifier for the object."),
  Object_Type STRING OPTIONS(description="Type or category of the object."),
  Object_Description STRING OPTIONS(description="Detailed description of the object.")
);

-- DDL for Relationship_Master Table
CREATE TABLE `sap-iac-test.bw2bq_migrate_dev.Relationship_Master` (
  Relationship_ID STRING NOT NULL OPTIONS(description="Unique identifier for the relationship type."),
  Relationship_Description STRING OPTIONS(description="Detailed description of the relationship."),
  Relation_Type STRING OPTIONS(description="Categorization of the relationship type (e.g., 'parent-child', 'associated-with').")
);

-- DDL for Relationship_Table
CREATE TABLE `sap-iac-test.bw2bq_migrate_dev.Relationship_Table` (
  Source_Object_ID STRING NOT NULL OPTIONS(description="Identifier of the source object, referencing Object_Master.Object_ID."),
  Relationship_ID STRING NOT NULL OPTIONS(description="Identifier of the relationship type, referencing Relationship_Master.Relationship_ID."),
  Target_Object_ID STRING NOT NULL OPTIONS(description="Identifier of the target object, referencing Object_Master.Object_ID.")
);