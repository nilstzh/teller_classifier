defmodule ClassifierTest do
  use ExUnit.Case
  alias Classifier

  @sample_json """
  {
    "app1": ["Payload/App1.app/dir1/", "Payload/App1.app/dir2/", "Payload/app_name.app/dir2/file"],
    "app2": ["Payload/App2.app/dir1/", "Payload/App2.app/dir2/", "Payload/App2.app/view.nib/"],
    "app3": ["Payload/App3.app/dir3/", "Payload/App3.app/dir4/", "Payload/App3.app/another.lproj/dir/"],
    "app4": ["Payload/App4.app/dir3/", "Payload/App4.app/dir4/", "Payload/App4.app/aaa-bc-3de-view-fg4-hj-kl5.nib/"]
  }
  """

  setup do
    {:ok, paths_data: Jason.decode!(@sample_json)}
  end

  test "normalize_paths/1 replaces app names with 'app_name'", %{paths_data: paths_data} do
    result = Classifier.normalize_paths(paths_data)

    assert {"app1",
            [
              "Payload/app_name.app/dir1/",
              "Payload/app_name.app/dir2/",
              "Payload/app_name.app/dir2/file"
            ]} in result

    assert {"app2",
            [
              "Payload/app_name.app/dir1/",
              "Payload/app_name.app/dir2/",
              "Payload/app_name.app/view.nib/"
            ]} in result

    assert {"app3",
            [
              "Payload/app_name.app/dir3/",
              "Payload/app_name.app/dir4/",
              "Payload/app_name.app/another.lproj/dir/"
            ]} in result

    assert {"app4",
            [
              "Payload/app_name.app/dir3/",
              "Payload/app_name.app/dir4/",
              "Payload/app_name.app/aaa-bc-3de-view-fg4-hj-kl5.nib/"
            ]} in result
  end

  test "filter_paths/1 removes specific files and directories", %{paths_data: paths_data} do
    normalized_paths = Classifier.normalize_paths(paths_data)
    result = Classifier.filter_paths(normalized_paths)

    assert {"app1", MapSet.new(["Payload/app_name.app/dir1/", "Payload/app_name.app/dir2/"])} in result

    assert {"app2",
            MapSet.new([
              "Payload/app_name.app/dir1/",
              "Payload/app_name.app/dir2/",
              "Payload/app_name.app/view.nib/"
            ])} in result

    assert {"app3",
            MapSet.new([
              "Payload/app_name.app/dir3/",
              "Payload/app_name.app/dir4/"
            ])} in result

    assert {"app4",
            MapSet.new([
              "Payload/app_name.app/dir3/",
              "Payload/app_name.app/dir4/"
            ])} in result
  end

  test "clusterize/1 correctly groups similar apps", %{paths_data: paths_data} do
    normalized_paths = Classifier.normalize_paths(paths_data)
    filtered_paths = Classifier.filter_paths(normalized_paths)
    result = Classifier.clusterize(filtered_paths, 0.7)

    assert length(result) == 2
    assert Enum.any?(result, &("app1" in &1 and "app2" in &1))
    assert Enum.any?(result, &("app3" in &1 and "app4" in &1))
  end

  test "similarity/2 calculates correct similarity between sets" do
    set1 = MapSet.new([["a", "b", "c"], ["d", "e", "f"]])
    set2 = MapSet.new([["a", "b", "c"], ["x", "y", "z"]])
    set3 = MapSet.new([["a", "b", "c"], ["d", "e", "f"]])

    assert Classifier.similarity(set1, set2) == 0.5
    assert Classifier.similarity(set1, set3) == 1.0
  end

  test "run/0 correctly processes and clusters data" do
    # Mock file reading and decoding
    File.write!("test/input.json", @sample_json)

    Classifier.run("test/input.json", "test/output.json", 0.7)

    result = File.read!("test/output.json") |> Jason.decode!()

    assert length(result) == 2
    assert Enum.any?(result, &("app1" in &1 and "app2" in &1))
    assert Enum.any?(result, &("app3" in &1 and "app4" in &1))

    # Clean up the test file
    File.rm!("test/input.json")
    File.rm!("test/output.json")
  end
end
