bestmp4() {
  for input_file in "$@"; do
    # Verificar si el archivo existe antes de proceder
    if [ -f "$input_file" ]; then
      # Obtener el nombre del archivo sin la extensión
      output_file="${input_file%.*}.mp4"

      # Obtener la duración total del video en segundos
      duration=$(ffmpeg -i "$input_file" 2>&1 | grep "Duration" | awk '{print $2}' | tr -d ,)
      total_seconds=$(echo "$duration" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')

      # Ejecutar ffmpeg con el progreso enviado a la consola y sobrescribir el archivo si existe
      start_time=$(date +%s)
      ffmpeg -y -i "$input_file" -c:v libx264 -preset slow -crf 18 -c:a aac -b:a 192k "$output_file" -progress pipe:1 2>&1 |
        while IFS= read -r line; do
          # Buscar líneas que contengan el tiempo de progreso
          if [[ $line =~ time=([0-9]{2}):([0-9]{2}):([0-9]{2}) ]]; then
            # Extraer el tiempo de la línea
            time=$(echo "$line" | grep -o "time=[0-9:.]*" | cut -d= -f2)

            # Convertir tiempo actual a segundos
            current_seconds=$(echo "$time" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')

            # Calcular el porcentaje de progreso
            progress=$(awk 'BEGIN { printf "%.2f\n", ('$current_seconds' / '$total_seconds') * 100 }')

            # Calcular el tiempo transcurrido
            elapsed_time=$(($(date +%s) - start_time))

            # Estimar el tiempo restante
            if ((current_seconds > 0)); then
              remaining_seconds=$(((elapsed_time * total_seconds / current_seconds) - elapsed_time))
              # Formatear el tiempo restante como HH:MM:SS
              eta=$(printf '%02d:%02d:%02d' $((remaining_seconds / 3600)) $(((remaining_seconds / 60) % 60)) $((remaining_seconds % 60)))
            else
              eta="calculando..."
            fi

            # Mostrar el progreso con ETA
            printf "\rConvirtiendo '%s': %.2f%% completado... ETA: %s" "$input_file" "$progress" "$eta"
          fi
        done

      echo -e "\nEl archivo '$input_file' ha sido convertido y guardado como: $output_file"
    else
      echo "El archivo '$input_file' no existe. Saltando..."
    fi
  done
}
