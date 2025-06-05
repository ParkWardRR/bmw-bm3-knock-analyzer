#!/bin/bash

# --- USER EDITABLE SECTION ---
INPUT_DIR="/Users/ParkWardRR/Desktop/BM3/Input"    # Directory containing your BM3 log CSVs
OUTPUT_PREFIX="knock-analysis"                # Prefix for output knock event files
BUFFER_PERCENT=10                             # Number of rows before/after a knock event to include for context
MERGE_FINAL="combined_knocks.csv"             # Name for the merged knock events file
MERGE_ALL="all_logs_concatenated.csv"         # Name for the concatenated all-logs file

# ENGINE-SPECIFIC PARAMETERS (edit if your logs use different column names)
KNOCK_COLUMN_NAME="Knock Detected[0/1]"       # Column name for knock detection (0 = no knock, 1 = knock)
THROTTLE_COLUMN_NAME="Accel. Pedal[%]"        # Column name for throttle pedal position (%)
IAT_COLUMN_NAME="IAT[F]"                      # Column name for Intake Air Temperature (°F)
# --- END USER EDITABLE SECTION ---

PARENT_DIR=$(dirname "$INPUT_DIR")
OUTPUT_BASE="${PARENT_DIR}/Output"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
FINAL_OUTPUT="${OUTPUT_BASE}/${TIMESTAMP}"

CHECKSUM_FILE="${FINAL_OUTPUT}/checksums.txt"
VALIDATION_FILE="${FINAL_OUTPUT}/validation.txt"
TERM_OUTPUT="${FINAL_OUTPUT}/term_output.txt"

mkdir -p "$FINAL_OUTPUT"
> "$CHECKSUM_FILE"
> "$VALIDATION_FILE"

total_knocks=0
total_files=0

echo "🔧 BMW N20 Knock Analysis Suite"
echo "==============================="
echo "📂 Input: ${INPUT_DIR}"
echo "📁 Output: ${FINAL_OUTPUT}"
echo ""
echo "⚙️  Engine-specific log columns:"
echo "    Knock:    ${KNOCK_COLUMN_NAME}"
echo "    Throttle: ${THROTTLE_COLUMN_NAME}"
echo "    IAT:      ${IAT_COLUMN_NAME}"
echo ""

first=1
for file in "${INPUT_DIR}"/*.csv; do
  if [[ $first -eq 1 ]]; then
    cat "$file" > "${FINAL_OUTPUT}/${MERGE_ALL}"
    first=0
  else
    tail -n +2 "$file" >> "${FINAL_OUTPUT}/${MERGE_ALL}"
  fi
done

for file in "${INPUT_DIR}"/*.csv; do
  filename=$(basename "$file")
  RAND_ID=$(jot -r 1 1000 9999)
  KNOCK_FILE="${FINAL_OUTPUT}/${OUTPUT_PREFIX}-${RAND_ID}.csv"
  checksum=$(md5 -q "$file")
  echo "${filename} ${checksum}" >> "$CHECKSUM_FILE"

  header=$(head -1 "$file")
  IFS=',' read -r -a cols <<< "$header"
  unset knock_col throttle_col iat_col
  for i in "${!cols[@]}"; do
    [[ "${cols[$i]}" == "$KNOCK_COLUMN_NAME" ]] && knock_col=$((i+1))
    [[ "${cols[$i]}" == "$THROTTLE_COLUMN_NAME" ]] && throttle_col=$((i+1))
    [[ "${cols[$i]}" == "$IAT_COLUMN_NAME" ]] && iat_col=$((i+1))
  done

  if [[ -z $knock_col || -z $throttle_col || -z $iat_col ]]; then
    echo "⚠️  Skipping $filename (missing expected columns)" | tee -a "$VALIDATION_FILE"
    echo "    (Expected: '$KNOCK_COLUMN_NAME', '$THROTTLE_COLUMN_NAME', '$IAT_COLUMN_NAME')" | tee -a "$VALIDATION_FILE"
    continue
  fi

  awk -F',' -v buffer="$BUFFER_PERCENT" -v outfile="$KNOCK_FILE" \
      -v knock_col="$knock_col" -v throttle_col="$throttle_col" -v iat_col="$iat_col" '
    NR==1 { header=$0; print header > outfile; next }
    {
      knocks[NR]=$knock_col > 0 ? $knock_col : 0
      throttles[NR]=$throttle_col+0
      iats[NR]=$iat_col+0
      lines[NR]=$0
      if ($knock_col == 1) { knock_lines[NR]=1; knock_count++ }
      if ($throttle_col+0 > max_throttle) max_throttle=$throttle_col+0
      if ($iat_col+0 > max_iat) max_iat=$iat_col+0
    }
    END {
      if (knock_count > 0) {
        for (k in knock_lines) {
          start = k - buffer > 1 ? k - buffer : 1
          end = k + buffer < NR ? k + buffer : NR
          for (i=start; i<=end; i++) if (!printed[i]++) print lines[i] >> outfile
        }
      }
      if (knock_count > 0)
        print "🔥 Knock Events: " knock_count " in " FILENAME
      else
        print "✅ Confirmed: 0 knock events found in " FILENAME
      print "🌡️ Max IAT: " (max_iat ? max_iat : "N/A") "°F in " FILENAME
      print "🎚️ Max Throttle: " (max_throttle ? max_throttle : "N/A") "% in " FILENAME
      print "-----------------"
    }' "$file" >> "$VALIDATION_FILE"

  # --- KNOCK EVENT COUNTING ---
  file_knocks=$(awk '/🔥 Knock Events:/ {print $4}' "$VALIDATION_FILE" | tail -1)
  (( total_knocks += file_knocks ))
  (( total_files++ ))
done

echo "🔗 Merging knock files..."
awk '
FNR == 1 && NR != 1 { next }
{ print }' "${FINAL_OUTPUT}"/*.csv > "${FINAL_OUTPUT}/${MERGE_FINAL}"

merged_checksum=$(md5 -q "${FINAL_OUTPUT}/${MERGE_FINAL}")
echo "Merged_File ${merged_checksum}" >> "$CHECKSUM_FILE"
all_logs_checksum=$(md5 -q "${FINAL_OUTPUT}/${MERGE_ALL}")
echo "All_Logs_File ${all_logs_checksum}" >> "$CHECKSUM_FILE"

{
echo ""
echo "✅ Processing Complete"
echo "---------------------"
echo "📊 Results Summary:"
echo "- Total knock files: $total_files"
echo "- Total knock events: $total_knocks"
echo "- Merged knock event CSV: ${FINAL_OUTPUT}/${MERGE_FINAL}"
echo "- All logs concatenated CSV: ${FINAL_OUTPUT}/${MERGE_ALL}"
echo "- Timestamp: ${TIMESTAMP}"
echo ""
echo "Validation Report:"
cat "$VALIDATION_FILE"
echo -e "\nChecksum Verification:"
cat "$CHECKSUM_FILE"
if [[ $total_knocks -eq 0 ]]; then
  echo "✅ Confirmed: 0 knock events found in all input files."
fi
} | tee "$TERM_OUTPUT"
