CREATE TRIGGER "rules_v2_insert" AFTER INSERT ON "rules_v2"
FOR EACH ROW EXECUTE FUNCTION rules_v2_insert();
