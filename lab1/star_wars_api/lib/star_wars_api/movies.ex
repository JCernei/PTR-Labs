defmodule StarWarsApi.Movies do
  import Ecto.Query, warn: false
  alias StarWarsApi.Repo

  alias StarWarsApi.Movies.Movie

  def list_movies do
    Repo.all(Movie)
  end

  def get_movie!(id), do: Repo.get!(Movie, id)

  def create_movie(attrs \\ %{}) do
    %Movie{}
    |> Movie.changeset(attrs)
    |> Repo.insert()
  end

  def update_movie(%Movie{} = movie, attrs) do
    movie
    |> Movie.update_changeset(attrs)
    |> Repo.update()
  end

  def patch_movie(%Movie{} = movie, attrs) do
    movie
    |> Movie.changeset(attrs)
    |> Repo.update()
  end

  def delete_movie(%Movie{} = movie) do
    Repo.delete(movie)
  end

  def change_movie(%Movie{} = movie, attrs \\ %{}) do
    Movie.changeset(movie, attrs)
  end
end
