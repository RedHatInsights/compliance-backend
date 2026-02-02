CREATE TRIGGER "v1_value_definitions_insert" INSTEAD OF INSERT ON "v1_value_definitions"
FOR EACH ROW EXECUTE FUNCTION v1_value_definitions_insert();
