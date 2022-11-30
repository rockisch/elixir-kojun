defmodule Item do
  @enforce_keys [:group]
  defstruct [:group, :value]
end

defmodule KojunParser do
  def parse_file(filename) do
    data = File.read!(filename)
    data = for {items, i} <- Enum.with_index(String.split(data, "\n")), String.length(items) > 0, {item, j} <- Enum.with_index(String.split(items)) do
      {{j, i}, parse_item(item)}
    end |> Map.new
    groups = parse_groups(data)
    data = parse_data(data, groups)
    {data, groups}
  end

  def parse_item(item) do
    {group, value} = String.split_at(item, 1)
    item = %Item{group: String.to_atom(group)}
    if value in ["", "-"] do
      item
    else
      %Item{item | value: [String.to_integer(value)]}
    end
  end

  def parse_groups(data) do
    Enum.group_by(data, fn {_, item} -> item.group end, fn {coord, _} -> coord end)
  end

  def parse_data(data, groups) do
    for {coord, item} <- data do
      group = groups[item.group]
      {
        coord,
        case item.value do
          nil -> %{item | value: Enum.to_list(1..length(group))}
          _ -> item
        end
      }
    end |> Map.new
  end
end

defmodule Kojun do
  def print(data) do
    keys = Map.keys(data)
    max_x = Enum.max(Enum.map(keys, &(elem(&1, 0))))
    max_y = Enum.max(Enum.map(keys, &(elem(&1, 1))))
    for y <- (0..max_y) do
      for x <- (0..max_x) do
        item = data[{x, y}]
        value = case item.value do
          [v] -> v
          vs -> Enum.map(vs, &Integer.to_string/1)
        end
        IO.write("#{item.group}#{value}\t")
      end
      IO.puts("")
    end
    IO.puts("")
  end

  def solve_file(filename) do
    {data, groups} = KojunParser.parse_file(filename)
    result = solve(data, groups)
    IO.puts("RESULT")
    print(result)
    result
  end

  def solve(data, groups) do
    new_data = simplify(data, groups)
    cond do
      is_solved(new_data) ->
        new_data
      true ->
        choose_and_solve(new_data, groups)
    end
  catch
    _ -> nil
  end

  def choose_and_solve(data, groups) do
    {coord, item} = Enum.find(data, nil, fn {_, item} -> length(item.value) > 1 end)
    [head | tail] = item.value
    result = Map.put(data, coord, %Item{item | value: [head]}) |> solve(groups)
    if result == nil do
      Map.put(data, coord, %Item{item | value: tail}) |> solve(groups)
    else
      result
    end
  end

  def data_coords_values(coords, data) do
    Enum.reduce(coords, [], fn coord, acc ->
      case data[coord] do
        %Item{value: [x]} -> [x | acc]
        _ -> acc
      end
    end)
  end

  def simplify(data, groups) do
    new_data = data |> simplify_adjascent() |> simplify_same_group(groups) |> simplify_above_group()
    if new_data == data do
      new_data
    else
      simplify(new_data, groups)
    end
  end

  def simplify_adjascent(data) do
    Map.new(data, fn {coord, item} ->
      {x, y} = coord
      values = Enum.reduce([{x+1, y}, {x-1, y}, {x, y+1}, {x, y-1}], item.value, fn c, acc ->
        case data[c] do
          %Item{value: [x]} -> List.delete(acc, x)
          _ -> acc
        end
      end)
      if values == [], do: throw :fail
      {coord, %Item{item | value: values}}
    end)
  end

  def simplify_same_group(data, groups) do
    Map.new(data, fn {coord, item} ->
      values = Enum.reduce(List.delete(groups[item.group], coord), item.value, fn c, acc ->
        case data[c] do
          %Item{value: [x]} -> List.delete(acc, x)
          _ -> acc
        end
      end)
      if values == [], do: throw :fail
      {coord, %Item{item | value: values}}
    end)
  end

  def simplify_above_group(data) do
    Map.new(data, fn {coord, item} ->
      {x, y} = coord
      group = item.group
      case data[{x, y-1}] do
        %Item{group: ^group, value: [v]} ->
          values = Enum.filter(item.value, &(&1 < v))
          if values == [], do: throw :fail
          {coord, %Item{item | value: values}}
        _ ->
          {coord, item}
      end
    end)
  end

  def is_solved(data) do
    Enum.all?(data, fn {_, item} -> length(item.value) == 1 end)
  end
end
