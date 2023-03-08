defmodule StarWarsApi.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add(:title, :string)
      add(:release_year, :integer)
      add(:director, :string)
    end

    create(unique_index(:movies, [:title, :release_year]))``
  end
end
