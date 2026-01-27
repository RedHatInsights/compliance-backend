CREATE TRIGGER "v1_benchmarks_update" INSTEAD OF UPDATE ON "v1_benchmarks"
FOR EACH ROW EXECUTE FUNCTION v1_benchmarks_update();
