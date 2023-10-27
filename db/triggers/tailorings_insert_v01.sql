CREATE TRIGGER "tailorings_insert" INSTEAD OF INSERT ON "tailorings"
FOR EACH ROW EXECUTE FUNCTION tailorings_insert();
