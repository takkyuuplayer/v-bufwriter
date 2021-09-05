# v-bufwriter

![CI](https://github.com/takkyuuplayer/v-bufwriter/workflows/CI/badge.svg)

Port of Go's bufio.Writer

```v
import os
import takkyuuplayer.bufwriter

fn main() {
	mut output := os.stdout()
	mut buf := bufwriter.new(writer: output)
	buf.write('abc'.bytes()) ? // No Output
	buf.flush() ? // Output: abc
}
```
