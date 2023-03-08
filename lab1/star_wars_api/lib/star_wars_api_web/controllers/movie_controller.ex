defmodule StarWarsApiWeb.MovieController do
  use StarWarsApiWeb, :controller

  alias StarWarsApi.Movies
  alias StarWarsApi.Movies.Movie

  action_fallback(StarWarsApiWeb.FallbackController)

  def index(conn, _params) do
    movies = Movies.list_movies()
    render(conn, :index, movies: movies)
  end

  def create(conn, %{"movie" => movie_params}) do
    with {:ok, %Movie{} = movie} <- Movies.create_movie(movie_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/movies/#{movie}")
      |> render(:show, movie: movie)
    end
  end

  def show(conn, %{"id" => id}) do
    movie = Movies.get_movie!(id)
    render(conn, :show, movie: movie)
  end

  def update(conn, %{"id" => id, "movie" => movie_params}) do
    movie = Movies.get_movie!(id)

    with {:ok, %Movie{} = movie} <- Movies.update_movie(movie, movie_params) do
      render(conn, :show, movie: movie)
    end
  end

  def patch(conn, %{"id" => id, "movie" => movie_params}) do
    movie = Movies.get_movie!(id)

    with {:ok, %Movie{} = movie} <- Movies.patch_movie(movie, movie_params) do
      render(conn, :show, movie: movie)
    end
  end

  def delete(conn, %{"id" => id}) do
    movie = Movies.get_movie!(id)

    with {:ok, %Movie{}} <- Movies.delete_movie(movie) do
      send_resp(conn, :no_content, "")
    end
  end
end
