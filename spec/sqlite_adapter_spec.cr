require "./spec_helper"

describe "SqliteAdapter" do
  people = SqliteAdapter::Adapter.new("people", "id", [
    "id", "last_name", "first_name", "number_of_dependents",
    "special_tax_group"
  ], false)
  something_else = SqliteAdapter::Adapter.new("something_else", "id", [
    "id", "name"
  ], false)
  posts = SqliteAdapter::Adapter.new("posts", "id", [
    "id", "title", "content", "created_at"
  ], false)

  describe "initialize" do
    it "queries column types" do
      people.types.should eq({
        "id": "integer",
        "last_name": "varchar(50)",
        "first_name": "varchar(50)",
        "number_of_dependents": "int",
        "special_tax_group": "boolean"
      })
      something_else.types.should eq({
        "id": "integer",
        "name": "varchar(50)"
      })
      posts.types.should eq({
        "id": "integer",
        "title": "varchar(50)",
        "content": "varchar(50)",
        "created_at": "datetime"
      })
    end
  end

  describe "#extract_fields" do
    it "correctly parses various data types" do
      data = [0, "doe", "john", 23, 1] # tests boolean
      people.extract_fields(data)["special_tax_group"].should be_true

      data = [0, "lorem ipsum", "lorem ipsum dolor sit amet",
        "2015-11-27 22:44:36"]
      posts.extract_fields(data)["created_at"].should eq(
        Time.parse("2015-11-27 22:44:36", "%Y-%m-%d %H:%M:%S", Time::Kind::Utc))
    end
  end
end
