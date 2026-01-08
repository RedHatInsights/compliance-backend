CREATE TRIGGER "rules_v2_delete" BEFORE DELETE ON "rules_v2"
FOR EACH ROW EXECUTE FUNCTION rules_v2_delete();
