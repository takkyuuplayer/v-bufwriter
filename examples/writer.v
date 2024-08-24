import os
import bufwriter

fn main() {
	mut output := os.stdout()
	mut buf := bufwriter.new(writer: output)
	buf.write('abc'.bytes())! // Output:
	buf.flush()! // Output: abc
}
