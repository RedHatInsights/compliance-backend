CREATE TRIGGER "rules_v2_update" BEFORE UPDATE ON "rules_v2"
FOR EACH ROW EXECUTE FUNCTION rules_v2_update();
