defmodule OldCode do

  def get_uniq_pairs(list) do
    r = Enum.reduce(list, {1, list, []}, fn
      x, acc ->
        {i, sublist, pairs} = acc
        tail = sublist |> Enum.drop(1)
        new_pairs = Enum.reduce(tail, [], fn
          y, pair_acc ->
            pair_acc ++ [{x, y}]
        end)
        {i+1, tail, pairs ++ new_pairs}
      end)
    {_count, _list, pairs} = r
    pairs
  end

  ######################################################

  def insert_student(assignments, teacher, student) do

    i = Enum.find_index(assignments, fn(x) ->
      Map.fetch!(x, :teacher) == teacher
    end)

    if i == nil do raise(ArgumentError, message: "Teacher not in assignment list") end

    assignment = Enum.at(assignments, i)

    {_oldAssinments, assignment} =
      Map.get_and_update(assignment, :students, fn current_students ->
        #{current_students, [student | current_students]}
        {current_students, current_students ++ [student]}
      end )

    assignments |> List.update_at(i, fn _x -> assignment end)

  end

  ######################################################

  def generate_assignment_list(teachers) do
    Enum.reduce(teachers, [], fn
      x, acc ->
        acc ++ [%{teacher: x, students: [], batch_size: 1}]
      end)
  end

  ######################################################

  def set_batch_sizes(assignments, batch_sizes) do

    Enum.reduce(batch_sizes, assignments, fn tuple, assignments ->
      {teacher, batch_size} = tuple

      i = Enum.find_index(assignments, fn(t) ->
        Map.fetch!(t, :teacher) == teacher
      end)

      assignment = Enum.at(assignments, i)

      {_oldAssinment, assignment} =
        Map.get_and_update(assignment, :batch_size, fn old_batch_size ->
          {old_batch_size, batch_size}
        end)

      assignments |> List.update_at(i, fn _x -> assignment end)

    end)

  end

  ######################################################

  def get_batch_count(assignments) do
    Enum.reduce(assignments, 0, fn x, acc ->
      acc + Map.fetch!(x, :batch_size)
    end)
  end

  def get_max_batch(student_count, batch_count) do
      assignment_count = student_count * 2
      remainder = rem assignment_count, batch_count
      case remainder do
        0 -> div assignment_count, batch_count
        _r -> 1 + div assignment_count, batch_count
      end
  end

  ######################################################

  # def assign_four_percent(assignments, teachers, students) do
  #   student_count = Enum.count(students)
  #   four_percent = round(Float.ceil 0.04 * student_count)
  #   {four_percent, remaining_students} = Enum.split(students, four_percent)
  #
  #   assignments =
  #     Enum.reduce(teachers, assignments, fn t, assignments ->
  #       Enum.reduce(four_percent, assignments, fn s, assignments ->
  #         insert_student(assignments, t, s)
  #       end)
  #     end)
  #
  #   {assignments, remaining_students}
  #
  # end

  def get_sample_percent(students, percent \\ 4) do
    student_count = Enum.count(students)
    sample_count = round(Float.ceil (percent / 100) * student_count )
    #{sample, remaining_students} =
      Enum.split(students, sample_count)
  end

  def assign_each(assignments, teachers, students) do
    Enum.reduce(teachers, assignments, fn t, assignments ->
      Enum.reduce(students, assignments, fn s, assignments ->
        insert_student(assignments, t, s)
      end)
    end)
  end

  ######################################################
  def get_teacher_map(assignments, teacher) do
    Enum.at(assignments,
      Enum.find_index(assignments, fn(t) ->
        Map.fetch!(t, :teacher) == teacher
      end)
    )
  end

  def current_column(assignment) do
    batch_size = Map.fetch!(assignment, :batch_size)
    current_student_count = Enum.count(Map.fetch!(assignment, :students))
    div current_student_count, batch_size

    # case rem current_student_count, batch_size do
    #   0 -> div current_student_count, batch_size
    #   _x -> 1 + div current_student_count, batch_size
    # end

  end

  def current_column(assignments, teacher) do
    current_column(get_teacher_map(assignments, teacher))
  end

  def batches_filled?(assignment, max) do
    batch_size = Map.fetch!(assignment, :batch_size)
    current_student_count = Enum.count(Map.fetch!(assignment, :students))
    #IO.puts "              (#{current_student_count})"
    current_student_count / batch_size >= max
  end

  def batches_filled?(assignments, teacher, max) do
    batches_filled?(get_teacher_map(assignments, teacher), max)
  end
  ######################################################

  def extract_ids(batch_list) do
    Enum.reduce(batch_list, [], fn {id, _}, acc ->
      acc ++ [id]
    end)
  end

  ######################################################

  def assigner(teachers, students) do

    #Refactor these two lines, I'm too lazy at the moment
    batch_sizes = teachers
    teachers = extract_ids(teachers)


    assignments = generate_assignment_list(teachers)
    teacherPairs = get_uniq_pairs(teachers)

    #batch_sizes = [{1, 2}, {3, 2}, {4, 2}, {6, 2}]
    assignments = set_batch_sizes(assignments, batch_sizes)


    #{assignments, students} = assign_four_percent(assignments, teachers, students)
    {sample, students} = get_sample_percent(students)

    batch_count = get_batch_count(assignments)
    batch_max = get_max_batch(Enum.count(students), batch_count)
    #IO.puts "Max Batch Size: #{batch_max}"

    {assignments, _, _, _} = Enum.reduce(students, {assignments, teacherPairs, 0, 0}, fn s, acc ->
      case acc do
        {asn, [], i, c} ->
          {t1, t1i, c} = get_next_assignable_teacher(asn, i, c)
            #oldc1 = current_column(asn, t1)
          asn = insert_student(asn, t1, s)
            #newc1 = current_column(asn, t1)
            #IO.puts "insert_student: #{s} - [#{t1}, #{c}] - (#{oldc1} -> #{newc1})"


          {t2, i, c} = get_next_assignable_teacher(asn, t1i, c, t1i)
            #oldc2 = current_column(asn, t2)
          asn = insert_student(asn, t2, s)
            #newc2 = current_column(asn, t2)
            #IO.puts "insert_student: #{s} - [#{t2}, #{c}] - (#{oldc2} -> #{newc2})"

          {asn, [], i + 1, c}

        {asn, tp, i, c} ->
          [{t1, t2} | tp] = tp
          #IO.puts "Teachers: #{t1} - #{t2} / Student: #{s}"

          asn = insert_student(asn, t1, s)
          asn = insert_student(asn, t2, s)

          tp = remove_full_pairs(asn, tp, t1, batch_max)
          tp = remove_full_pairs(asn, tp, t2, batch_max)

          {asn, tp, i, c}

      end
    end)


    assign_each(assignments, teachers, sample)

  end

  ######################################################

  def remove_full_pairs(assignments, pairs, teacher, max) do
    if batches_filled?(assignments, teacher, max) do
      Enum.filter(pairs, fn({x, y}) -> x != teacher and y != teacher end)
    else
      pairs
    end
  end

  ######################################################

  def get_next_assignable_teacher(assignments, index, column, current \\ -1) do
    if index >= Enum.count(assignments) do
      min_col = Enum.reduce(assignments, -1, fn x, acc ->
        if acc == -1 do current_column(x)
        else if current_column(x) < acc do
            current_column(x)
          else
            acc
          end
        end
      end)

      get_next_assignable_teacher(assignments, 0, min_col, current)

    else
      assignment = Enum.at(assignments, index)
      if(current_column(assignment) > column or index == current) do
        get_next_assignable_teacher(assignments, index + 1, column, current)

      else
        {Map.fetch!(assignment, :teacher), index, column}

      end
    end
  end

  def alpha(x) do
    Enum.reduce(97..96 + x, [], fn x, acc -> acc ++ [String.to_atom(to_string([x]))] end)
  end


end
