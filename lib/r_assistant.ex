defmodule RAssistant do
  alias OpenaiEx.Beta.Assistants
  alias OpenaiEx.Beta.Threads
  alias OpenaiEx.Beta.Threads.Messages
  alias OpenaiEx.Beta.Threads.Runs

  @apikey System.fetch_env!("OPENAI_API_KEY")
  @openai OpenaiEx.new(@apikey)

  def start do
    assistant = create_assistant()
    thread = create_thread()
    IO.puts("Escribe 'END' para enviar tu mensaje o 'exit' para salir.")
    loop(assistant, thread)
  end

  defp create_assistant do
    %{"id" => id} = @openai |> Assistants.create(%{
      name: "R Assistant",
      description: "You are a helpful Data Scientist working with R",
      instructions: "You are a helpful Data Scientist working with R",
      tools: [%{type: "code_interpreter"}],
      model: "gpt-4o"
    })
    id
  end

  defp create_thread do
    %{"id" => id} = @openai |> Threads.create(%{
      instructions: "You are a helpful Data Scientist working with R",
      name: "helpful Data Scientist working with R",
      tools: [%{type: "code_interpreter"}],
      model: "gpt-4o"
    })
    id
  end

  defp loop(assistant, thread) do
    IO.puts("Introduce tu pregunta (para finalizar, escribe 'END' en una nueva línea):")
    input = get_multiline_input()

    if input == "exit\n" do
      IO.puts("Saliendo...")
    else
      process_input(input, assistant, thread)
      loop(assistant, thread)
    end
  end

  defp get_multiline_input do
    get_multiline_input("")
  end

  defp get_multiline_input(acc) do
    line = IO.gets("> ")

    if line == "END\n" do
      acc
    else
      get_multiline_input(acc <> line)
    end
  end

  defp process_input(input, assistant, thread) do
    @openai |> Messages.create(
      thread,
      %{
        role: "user",
        content: input
      }
    )
    run_req = Runs.new(thread_id: thread, assistant_id: assistant)

    run_stream = @openai |> Runs.create(run_req, stream: true)

    # Using Enum.reduce to get the last element
    last_element = run_stream.body_stream
                     |> Stream.flat_map(& &1)
                     |> Enum.reduce(nil, fn x, _acc -> x end)

    case last_element do
      %{event: "thread.run.completed"} ->
        # Execute the code for the completed event
        execute_completed_code(thread)

      _ ->
        IO.puts("Hubo un error")
    end
  end

  defp execute_completed_code(thread) do
    messages_response = @openai |> Messages.list(thread)
    # Accede a la lista de mensajes en la respuesta
    messages = messages_response["data"]

    # Asegúrate de que messages es una lista no vacía
    if is_list(messages) and length(messages) > 0 do
      # Accede al primer mensaje en la lista de datos
      first_message = hd(messages)

      # Accede al contenido del primer mensaje
      content = first_message["content"]

      # Extrae el valor del texto del contenido
      value = content
              |> hd()
              |> Map.get("text")
              |> Map.get("value")

      # Imprime el valor
      IO.puts(value)
    else
      IO.puts("No se encontraron mensajes.")
    end
  end
end
