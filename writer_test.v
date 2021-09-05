module bufwriter

import takkyuuplayer.bytebuf

fn test_new() {
	w := bytebuf.Buffer{}
	{
		writer := new(writer: w)

		assert writer.buf == []byte{len: 4096}
		assert writer.n == 0
		if writer.writer is bytebuf.Buffer {
			assert writer.writer == w
		} else {
			assert false
		}
	}
	{
		writer := new(writer: w, cap: 1024)

		assert writer.buf == []byte{len: 1024}
	}
	{
		writer := new(writer: w)
		w1 := new(writer: writer)

		assert w1.buf == writer.buf
		assert w1.n == writer.n
		if writer.writer is bytebuf.Buffer && w1.writer is bytebuf.Buffer {
			assert w1.writer == writer.writer
		} else {
			assert false
		}
	}
}

const bufsizes = [byte(0), 16, 23, 32, 46, 64, 93, 128, 1024, 4096]

fn test_writer() ? {
	{
		mut data := []byte{len: 8192}
		for i := 0; i < data.len; i++ {
			data[i] = byte(` ` + i % (`~` - ` `))
		}

		mut w := bytebuf.Buffer{}
		for nwrite in bufwriter.bufsizes {
			for bs in bufwriter.bufsizes {
				w.reset()

				mut buf := new(writer: w, cap: bs)
				assert buf.write(data[..nwrite]) ? == nwrite
				buf.flush() ?

				assert w.bytes() == data[..nwrite]
			}
		}
	}
}
