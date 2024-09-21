defmodule ChatgptCli do
  alias OpenaiEx.Chat
  alias OpenaiEx.ChatMessage

  @apikey System.fetch_env!("OPENAI_API_KEY")
  @openai OpenaiEx.new(@apikey)

  def start do
    IO.puts("Bienvenido al CLI. Escribe 'END' para enviar tu mensaje o 'exit' para salir.")
    loop()
  end

  defp loop do
    IO.puts("Introduce tu pregunta (para finalizar, escribe 'END' en una nueva línea):")

    input = get_multiline_input()

    if input == "exit" do
      IO.puts("Saliendo...")
    else
      process_input(input)
      loop()
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

  defp process_input(input) do
    # Configurar la solicitud de chat completion
    chat_req = Chat.Completions.new(
      model: "gpt-4o",
      messages: [
        ChatMessage.user(input)
      ]
    )

    Process.sleep 2000
    # Llamar a la API de OpenAI
    response = @openai |> Chat.Completions.create(chat_req)

    case response do
      %{"choices" => choices} ->
        Enum.each(choices, fn %{"message" => %{"content" => content}} ->
          IO.puts("R: #{content}")
        end)

      %{"error" => reason} ->
        IO.inspect(reason, label: "Error online:")
    end
  end
end
