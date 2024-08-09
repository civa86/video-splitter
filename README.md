# Video Splitter

Command Line Tool to split video files.

## Requirements

- ffmpeg [Official Site](https://www.ffmpeg.org)

## Installation

Put `vplit.sh` in your PATH and make it executable.

```bash
chmod +x ./vsplit.sh
ln -s /absolute/path/vsplit.sh /usr/local/bin/vsplit
```

## Usage

./vsplit.sh [options] input_file

options:

-h) Print this Help

-p) Number of parts to divide the input into. Optional (default 2)

-o) Output Path (default the same dir of the input)
