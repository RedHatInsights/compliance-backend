CREATE TRIGGER "v1_benchmarks_insert" INSTEAD OF INSERT ON "v1_benchmarks"
FOR EACH ROW EXECUTE FUNCTION v1_benchmarks_insert();
