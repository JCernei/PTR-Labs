# Use the official Elixir base image
FROM elixir:latest

# Set the working directory inside the container
RUN mkdir /app
WORKDIR /app

# Copy the project files into the container
COPY . /app

# Install dependencies
# RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get

# Compile the project
RUN mix compile

# Start the program
CMD mix run --no-halt