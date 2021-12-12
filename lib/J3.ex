defmodule J3 do
  @pos_far_left 1
  @pos_mid_left 2
  @pos_far_right 5

  @lady_1 ~s|Natsiou|
  @color_1 ~s|rouge|
  @lady_2 ~s|Marcolla|
  @color_2 ~s|vert|
  @color_3 ~s|violet|
  @color_4 ~s|blanc|
  @drink_1 ~s|absinthe|
  @city_1 ~s|Karnaca|
  @color_5 ~s|bleu|
  @object_1 ~s|bague|
  @lady_3 ~s|Winslow|
  @object_2 ~s|medaille|
  @city_2 ~s|Baleton|
  @object_3 ~s|diamant|
  @object_4 ~s|pendentif|
  @city_3 ~s|Dunwall|
  @drink_2 ~s|bière|
  @lady_4 ~s|Contee|
  @drink_3 ~s|rhum|
  @city_4 ~s|Fraeport|
  @drink_4 ~s|whisky|
  @drink_5 ~s|vin|
  @lady_5 ~s|Finch|
  @city_5 ~s|Dabokva|
  @object_5 hd(
              ~w(tabatiere diamant pendentif bague medaille) --
                [@object_1, @object_2, @object_3, @object_4]
            )

  defmodule Person do
    defstruct _n: nil,
              name: nil,
              color: nil,
              object: nil,
              city: nil,
              position: nil,
              drink: nil
  end

  defguard is_value(v) when is_integer(v) or is_binary(v)

  def names, do: [@lady_1, @lady_2, @lady_3, @lady_4, @lady_5]
  def positions, do: @pos_far_left..@pos_far_right
  def colors, do: [@color_1, @color_2, @color_3, @color_4, @color_5]
  def objects, do: [@object_1, @object_2, @object_3, @object_4, @object_5]
  def cities, do: [@city_1, @city_2, @city_3, @city_4, @city_5]
  def drinks, do: [@drink_1, @drink_2, @drink_3, @drink_4, @drink_5]

  # express that only people that have value_1 can have value_2.
  # - remove value_1 from people that do not have value_2
  # - remove value_2 from people that do not have value_1
  # - force only value_1 as choice for people that only have choice value_2
  # - force only value_2 as choice for people that only have choice value_1
  defp bind(key_1, value_1, key_2, value_2) when is_value(value_1) or is_value(value_2) do
    fn people ->
      people
      |> Enum.map(fn person ->
        person =
          if(not has_choice?(person, key_1, value_1),
            do: remove_choice(person, key_2, value_2),
            else: person
          )

        person =
          if(not has_choice?(person, key_2, value_2),
            do: remove_choice(person, key_1, value_1),
            else: person
          )

        person =
          if(has_single_choice?(person, key_1, value_1),
            do: put_single_choice(person, key_2, value_2),
            else: person
          )

        person =
          if(has_single_choice?(person, key_2, value_2),
            do: put_single_choice(person, key_1, value_1),
            else: person
          )

        person
      end)
    end
  end

  defp has_choice?(person, key, choice) when is_value(choice) do
    choice in Map.fetch!(person, key)
  end

  defp has_any_choice?(person, key, choices) when is_list(choices) do
    Enum.any?(choices, &has_choice?(person, key, &1))
  end

  defp has_single_choice?(person, key, choice) when is_value(choice) do
    [choice] == Map.fetch!(person, key)
  end

  defp put_single_choice(person, key, value) do
    Map.put(person, key, [value])
  end

  defp remove_choice(person, key, choice) do
    case Map.fetch!(person, key) do
      [^choice] ->
        raise "cannot remove the last choice for #{inspect(key)} #{inspect(choice)} from #{person._n}"

      list ->
        Map.put(person, key, list -- [choice])
    end
  end

  defp pluck(people, prop) do
    Enum.flat_map(people, &Map.fetch!(&1, prop))
  end

  defp unique(values) do
    values |> :lists.flatten() |> Enum.uniq()
  end

  defp left_of(position) when is_integer(position),
    do: position - 1

  defp left_of(positions) when is_list(positions),
    do: Enum.map(positions, &left_of/1) |> :lists.flatten() |> no_bad_poses()

  defp right_of(position) when is_integer(position),
    do: position + 1

  defp right_of(positions) when is_list(positions),
    do: Enum.map(positions, &right_of/1) |> :lists.flatten() |> no_bad_poses()

  defp neighbours_of(positions) when is_list(positions),
    do: positions |> Enum.map(&[left_of(&1), right_of(&1)]) |> :lists.flatten() |> no_bad_poses()

  defp no_bad_poses(poses) do
    poses -- [0, 6]
  end

  defp derive(data_gen, bind_gen) do
    fn people ->
      data = data_gen.(people)
      binder = bind_gen.(data)
      binder.(people)
    end
  end

  defp limit(ctrl_key, ctrl_values, unlink_key, unlink_value)
       when is_list(ctrl_values) and is_value(unlink_value) do
    fn people ->
      Enum.map(people, fn person ->
        if not has_any_choice?(person, ctrl_key, ctrl_values) do
          remove_choice(person, unlink_key, unlink_value)
        else
          person
        end
      end)
    end
  end

  defp remove(ctrl_key, single_value, rm_key, rm_choice) do
    fn people ->
      Enum.map(people, fn person ->
        if has_single_choice?(person, ctrl_key, single_value) do
          remove_choice(person, rm_key, rm_choice)
        else
          person
        end
      end)
    end
  end

  defp rules do
    [
      # Les femmes s'assirent en rang. Elles étaient toutes vêtues de couleurs
      # différentes, et madame Natsiou portait un élégant chapeau rouge.
      bind(:name, @lady_1, :color, @color_1),

      # À l'extrême gauche se trouvait le docteur Marcolla, à côté de la convive au
      # veston vert.
      bind(:name, @lady_2, :position, @pos_far_left),
      bind(:position, @pos_mid_left, :color, @color_2),

      # La dame en violet était assise à la gauche d'une personne en blanc. Je me
      # souviens de son habit violet, car elle l'avait taché d'absinthe.
      remove(:position, 1, :color, @color_3),
      remove(:position, 5, :color, @color_3),
      remove(:position, 1, :color, @color_4),
      remove(:position, 3, :color, @color_4),
      limit(:color, [@color_3, @color_4], :position, 4),
      bind(:color, @color_3, :drink, @drink_1),
      derive(
        fn people ->
          Enum.filter(people, &has_choice?(&1, :color, @color_4))
          |> pluck(:position)
          |> unique()
          |> left_of()
        end,
        fn violet_poses -> limit(:position, violet_poses, :color, @color_3) end
      ),
      derive(
        fn people ->
          Enum.filter(people, &has_choice?(&1, :color, @color_3))
          |> pluck(:position)
          |> unique()
          |> right_of()
        end,
        fn blanc_poses -> limit(:position, blanc_poses, :color, @color_4) end
      ),

      # La voyageuse venue de Karnaca portaint un ensemble bleu. Quand l'une des
      # invitées se vanta d'avoir une bague en sa possession, sa voisine déclara qu'on
      # trouvait largement mieux à Karnaca, où elle habitait.
      bind(:city, @city_1, :color, @color_5),
      derive(
        fn people ->
          Enum.filter(people, &has_choice?(&1, :city, @city_1))
          |> pluck(:position)
          |> unique()
          |> neighbours_of()
        end,
        fn
          [bague_pos] ->
            bind(:position, bague_pos, :object, @object_1)

          bague_poses ->
            bague_poses |> IO.inspect(label: ~S[bague_poses])
            limit(:position, bague_poses, :object, @object_1)
        end
      ),
      derive(
        fn people ->
          Enum.filter(people, &has_choice?(&1, :object, @object_1))
          |> pluck(:position)
          |> unique()
          |> neighbours_of()
        end,
        fn karnaca_poses -> limit(:position, karnaca_poses, :city, @city_1) end
      ),

      # Alors, dame Winslow exhiba fièrement une médaille de guerre de grande valeur,
      # dont la dame de Baleton s'empressa de se moquer en montrant à son tour un
      # diamant qui, selon elle, était bien plus remarquable.
      bind(:name, @lady_3, :object, @object_2),
      bind(:city, @city_2, :object, @object_3),

      # Une autre femme avait apporté un pendentif maginifique ; quand la visiteuse de
      # Dunwall à côté d'elle l'aperçut, elle faillit renverser le verre de bière de sa
      # voisine.
      bind(:object, @object_4, :drink, @drink_2),
      remove(:city, @city_3, :object, @object_4),
      remove(:city, @city_3, :drink, @drink_2),
      derive(
        fn people ->
          Enum.filter(people, &has_choice?(&1, :object, @object_4))
          |> pluck(:position)
          |> unique()
          |> neighbours_of()
        end,
        fn dunwall_poses -> limit(:position, dunwall_poses, :city, @city_3) end
      ),

      # Ensuite, la comtesse Contee se resservit un peut de rhum pour porter un toast.
      bind(:name, @lady_4, :drink, @drink_3),

      # La dame de Fraeport, grisée de whisky, sauta sur la table et tomba sur la
      # convive assise au centre, renversant le verre de vin de la pauvre femme.
      bind(:city, @city_4, :drink, @drink_4),
      remove(:city, @city_4, :position, 3),
      bind(:drink, @drink_5, :position, 3),

      # Plus tard, la baronne Finch captiva l'assemblée en racontant une histoire de sa
      # folle jeunesse à Dabokva.
      bind(:name, @lady_5, :city, @city_5),

      # Au matin, il y avait quatre objets de valeur sous la table : une bague, une
      # tabatière, une diamant et un pendentif.

      # Mais à qui chacun appartenait-il ?
      :noop
    ]
  end

  def run do
    people =
      for name <- names() do
        %Person{
          _n: name,
          name: [name],
          drink: drinks(),
          city: cities(),
          object: objects(),
          color: colors(),
          position: Enum.to_list(positions())
        }
      end

    rules()
    |> Stream.cycle()
    |> Stream.scan(people, &apply_rule/2)
    |> Enum.reduce_while(nil, fn people, _ ->
      if win?(people) do
        {:halt, people}
      else
        {:cont, nil}
      end
    end)
  end

  defp apply_rule(:noop, people) do
    people
  end

  defp apply_rule(rule, people) do
    new_people = rule.(people) |> reduce_choices() |> Enum.sort_by(&{&1.position, &1._n})
  end

  # scan all people. if people have a single value for a field, ensure that
  # value is removed from other people.
  defp reduce_choices(people) do
    names = Enum.map(people, & &1._n)

    Enum.reduce(names, people, fn name, acc ->
      {person, other_people} = take_person(acc, name)

      singles =
        person
        |> Map.from_struct()
        |> Enum.map(fn
          {k, [single_val]} -> {k, single_val}
          _ -> nil
        end)
        |> Enum.filter(&(&1 != nil))

      other_people =
        Enum.reduce(singles, other_people, fn {k, v}, acc ->
          Enum.map(acc, &remove_choice(&1, k, v))
        end)

      [person | other_people]
    end)
  end

  defp take_person(people, name) do
    {[person], other} = Enum.split_with(people, &(&1._n == name))
    {person, other}
  end

  defp win?(people) do
    Enum.all?(people, &(length(&1.name) == 1 and length(&1.object) == 1))
  end
end
