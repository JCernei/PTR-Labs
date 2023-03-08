defmodule StarWarsApiWeb.MovieControllerTest do
  use StarWarsApiWeb.ConnCase

  import StarWarsApi.MoviesFixtures

  alias StarWarsApi.Movies.Movie

  @create_attrs %{
    director: "some director",
    release_year: 42,
    title: "some title"
  }
  @update_attrs %{
    director: "some updated director",
    release_year: 43,
    title: "some updated title"
  }
  @invalid_attrs %{director: nil, release_year: nil, title: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all movies", %{conn: conn} do
      conn = get(conn, ~p"/api/movies")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create movie" do
    test "renders movie when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/movies", movie: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/movies/#{id}")

      assert %{
               "id" => ^id,
               "director" => "some director",
               "release_year" => 42,
               "title" => "some title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/movies", movie: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update movie" do
    setup [:create_movie]

    test "renders movie when data is valid", %{conn: conn, movie: %Movie{id: id} = movie} do
      conn = put(conn, ~p"/api/movies/#{movie}", movie: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/movies/#{id}")

      assert %{
               "id" => ^id,
               "director" => "some updated director",
               "release_year" => 43,
               "title" => "some updated title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, movie: movie} do
      conn = put(conn, ~p"/api/movies/#{movie}", movie: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete movie" do
    setup [:create_movie]

    test "deletes chosen movie", %{conn: conn, movie: movie} do
      conn = delete(conn, ~p"/api/movies/#{movie}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/movies/#{movie}")
      end
    end
  end

  defp create_movie(_) do
    movie = movie_fixture()
    %{movie: movie}
  end
end
