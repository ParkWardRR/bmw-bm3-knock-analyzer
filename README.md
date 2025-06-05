# BMW BM3 Knock Analyzer

## Overview

This is a bash script built for my 6-speed manual (6MT) F32 BMW 428i with the N20 engine. It automates the process of analyzing Bootmod3 (BM3) log CSVs to find knock events, add context, check data integrity, and generate summary reports. All output is timestamped and organized for easy review. If you're tuning or troubleshooting your BMW, this tool saves you hours of manual log-checking.


---

## Table of Contents

- [Screenshot](#screenshot)
- [Features](#features)
- [How to Use on macOS](#how-to-use-on-macos)
- [Uploading to Bootmod3 Log Viewer](#uploading-to-bootmod3-log-viewer)
- [How to Use the Output with AI Tools (GPT-4o, Claude, Perplexity, etc.)](#how-to-use-the-output-with-ai-tools-gpt-4o-claude-perplexity-etc)
- [Enhanced Analysis Workflow](#enhanced-analysis-workflow)
- [Tool-Specific Tips](#tool-specific-tips)
- [Example Output](#example-output)
- [How to Contribute Your Engine](#how-to-contribute-your-engine)
- [License](#license)


---

## Screenshot

![Screenshot](https://i.postimg.cc/NYq4wCph/1-copy.png "Screenshot")

---

## Features

- **Scans all BM3 log CSVs** in a folder.
- **Finds knock events** (where knock = 1).
- **Adds context**: grabs extra rows before and after each knock event.
- **Checks data integrity**: generates checksums for every file.
- **Summary report**: shows total knock events, max throttle, max IAT, and more.
- **Organized output**: everything is timestamped and saved in a new folder.
- **Handles logs with zero knock events** (won't crash or make empty files).
- **Merges all logs** into a single CSV for easier review.
- **Combined CSV is compatible with BM3’s online log viewer** for easy upload and sharing.

---

## How to Use on macOS

1. **Download the script**  
   Save the script as `bmw-bootmod3-knock-event-context-extractor.sh`.

2. **Make it executable**  
   Open Terminal, navigate to the folder with the script, and run:
   ```
   chmod +x bmw-bootmod3-knock-event-context-extractor.sh
   ```

3. **Edit the script for your setup**  
   - Open the script in a text editor.
   - Set `INPUT_DIR` to the folder where your BM3 log CSVs are stored.
   - (Optional) Adjust `BUFFER_PERCENT` for more or less context around knock events.

4. **Run the script**  
   ```
   ./bmw-bootmod3-knock-event-context-extractor.sh
   ```

5. **Check the Output**  
   - Look in the `Output` folder (created next to your `Input` folder).
   - Each run makes a new timestamped subfolder with all results inside.

---

## Uploading to Bootmod3 Log Viewer

![Log Viewer Screenshot](https://i.postimg.cc/KvV1fsJ7/1.png "Log Viewer Screenshot")

The script creates a `combined_knocks.csv` file that is fully compatible with the Bootmod3 (BM3) log viewer.

**To upload and review your knock events:**
1. Go to [https://www.bootmod3.net/www/index.html#/drawer/logs](https://www.bootmod3.net/www/index.html#/drawer/logs).
2. Drag and drop your `combined_knocks.csv` file into the BM3 log viewer.
3. You can now view, chart, and share your knock events directly on BM3, just like any log exported from the app.

This makes it easy to analyze knock patterns, zoom in on specific events, and share logs with your tuner for remote reviews.

---

## How to Use the Output with AI Tools (GPT-4o, Claude, Perplexity, etc.)

The script’s **context-rich CSV outputs** work especially well with modern AI tools like GPT-4o, Claude 3, Google Gemini, local LLMs (e.g., Llama 3-70B), and other platforms such as ChatGPT, Copilot, and Mistral. These smaller files avoid token limits while preserving critical diagnostic context.

---

### Enhanced Analysis Workflow

1. **Run the script**  
   ```bash
   ./bmw-bootmod3-knock-event-context-extractor.sh
   ```

2. **Upload to AI**  
   Use either:
   - `combined_knocks.csv` for full analysis
   - Individual timestamped CSV files from `Output/[timestamp]/` for focused reviews

3. **Use this expanded prompt template**  
   ```markdown
   Analyze this BMW N20 knock log CSV and:
   
   1. **Flag critical events**: Identify knock events where:
      - Knock value exceeds 1.0 (if present in data)
      - Knock occurs alongside IAT > 90°F **and** throttle > 75%
      - Consecutive knock events within 5 seconds
   
   2. **Assess data quality**:
      - Do the "context window" rows (before/after knock) show complete engine parameters?
      - Are there enough pre-knock rows to identify potential causes?
   
   3. **Identify correlations**:
      - Knock vs. specific gears/RPM ranges
      - Knock vs. coolant/oil temp combinations
      - Knock during overrun (throttle closing)
   
   4. **Explain anomalies**:
      - Highlight unusual AFR/IAT/boost relationships
      - Note timing pulls exceeding 3 degrees
      - Flag potential false positives (knock without load)
   
   5. **Provide tuning advice**:
      - Suggest fuel/ignition adjustments for problem areas
      - Recommend mechanical checks (plugs, coils, carbon buildup)
      - Propose logging adjustments for clearer diagnostics
   
   6. **Evaluate pull quality**:
      - Determine if the logged pulls are suitable for meaningful analysis (e.g., consistent throttle, proper gear, full sweep)
      - Note any runs that are too short, inconsistent, or missing key data
   
   Format results as bullet points with severity ratings (Low/Med/High). Provide clear explanations for each finding and highlight anything that should be brought to the user’s immediate attention.
   ```

---

### Tool-Specific Tips

| Tool           | Best For                          | Max Rows* | Formatting Tip                  |
|----------------|-----------------------------------|-----------|----------------------------------|
| GPT-4o         | Detailed tuning advice            | 10k       | Use **bold** for severity levels |
| Perplexity     | Quick correlations                | 5k        | Prefix questions with "Automotive:" |
| Claude 3       | Long-context analysis             | 15k       | Use markdown tables              |
| Local LLMs     | Sensitive data                    | Varies    | Specify "Use SAE units"          |

_*Typical row limits for free tiers. Paid plans often allow 50k+ rows._

---

Upload only the relevant context CSVs (not huge merged logs) for faster, more accurate AI analysis. Ask specific questions in your prompt for actionable answers, and if needed, upload multiple small CSVs one at a time and combine insights.

---
## Example Output

```
🔧 BMW N20 Knock Analysis Suite
===============================
📂 Input: /path/to/BM3/Input
📁 Output: /path/to/BM3/Output/20250604-165941

⚙️  Engine-specific log columns:
    Knock:    Knock Detected[0/1]
    Throttle: Accel. Pedal[%]
    IAT:      IAT[F]

🔗 Merging knock files...

✅ Processing Complete
---------------------
📊 Results Summary:
- Total knock files: 8
- Merged knock event CSV: /path/to/BM3/Output/20250604-165941/combined_knocks.csv
- All logs concatenated CSV: /path/to/BM3/Output/20250604-165941/all_logs_concatenated.csv
- Timestamp: 20250604-165941

Validation Report:
✅ Confirmed: 0 knock events found in /path/to/BM3/Input/683fcd3531e8341e8584cbb5.csv
🌡️ Max IAT: 88°F in /path/to/BM3/Input/683fcd3531e8341e8584cbb5.csv
🎚️ Max Throttle: 84% in /path/to/BM3/Input/683fcd3531e8341e8584cbb5.csv
-----------------
...
Checksum Verification:
683fcd3531e8341e8584cbb5.csv bbe5392ce842ea04f5f13e80fba9c110
...
Merged_File d48b4f6dc8c81ab1e4ebc97bd2ce3078
All_Logs_File d48b4f6dc8c81ab1e4ebc97bd2ce3078
✅ Confirmed: 0 knock events found in all input files.
```

---

## How to Contribute Your Engine

Want to add support for your own BMW engine (or any car with similar logs)?  
Here’s how:

1. **Find your log’s column names**  
   - Open a log CSV and note the exact column headers for knock detection, throttle, and IAT.

2. **Edit the script**  
   - At the top, look for the `ENGINE-SPECIFIC PARAMETERS` section.
   - Change these lines to match your log:
     ```
     KNOCK_COLUMN_NAME="Your Knock Column"
     THROTTLE_COLUMN_NAME="Your Throttle Column"
     IAT_COLUMN_NAME="Your IAT Column"
     ```

3. **Test with your logs**  
   - Run the script and make sure it finds knock events (if any) and produces correct output.

4. **Share your changes**  
   - Fork this repo on GitHub.
   - Commit your changes with a message like `Add support for B58 engine`.
   - Open a pull request (PR) and include:
     - Your engine type
     - The column names you used
     - Any tips or issues you found

5. **(Optional) Add a sample log**  
   - Include a small, anonymized log (just a few rows, no personal info) to help others test.

If you’re not sure how to make a PR, check GitHub’s [official guide](https://docs.github.com/en/get-started/quickstart/contributing-to-projects) or just open an issue with your info.

---

## License

MIT License (or whatever you pick when you set up the repo).

---

**Built for my 6MT F32 BMW 428i (N20 engine), but easy to adapt for other engines—just update the column names!**

