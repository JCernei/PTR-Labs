defmodule StarWarsApi.Movies.Movie do
  use Ecto.Schema
  import Ecto.Changeset

  schema "movies" do
    field(:director, :string)
    field(:release_year, :integer)
    field(:title, :string)
  end

  @doc false
  def changeset(movie, params) do
    movie
    |> cast(params, [:title, :release_year, :director])
    |> validate_required([:title, :release_year, :director])
    |> unique_constraint(:title, name: :index_movies_on_title_and_release_year)
  end

  @doc false
  def update_changeset(movie, params) do
    movie
    |> cast(params, [:title, :release_year, :director])
    |> validate_required([:title, :release_year, :director])
    |> unique_constraint(:title, name: :index_movies_on_title_and_release_year)
    |> require_all_fields()
  end

  @doc false
  defp require_all_fields(changeset) do
    fields = [:title, :release_year, :director]
    Enum.reduce(fields, changeset, fn field, changeset ->
      case get_change(changeset, field) do
        nil ->
          add_error(changeset, field, "A new value must be provided")
        _ ->
          changeset
      end
    end)
  end
end
