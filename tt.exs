J3.run()
|> Enum.each(fn %J3.Person{_n: name, object: [object]} ->
  IO.puts("#{name}: #{object}")
end)
