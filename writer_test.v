module bufwriter

import takkyuuplayer.bytebuf

fn test_new() {
	w := bytebuf.Buffer{}
	writer := new(w)

	assert writer.buf == []byte{len: 4096}
	assert writer.n == 0
	if writer.wr is bytebuf.Buffer {
		assert writer.wr == w
	} else {
		assert false
	}
}

fn test_new_size() {
	{
		w := bytebuf.Buffer{}
		writer := new_size(w, 8192)

		assert writer.buf == []byte{len: 8192}
		assert writer.n == 0
		if writer.wr is bytebuf.Buffer {
			assert writer.wr == w
		} else {
			assert false
		}
	}
	{
		w := bytebuf.Buffer{}
		writer := new_size(w, 8192)
		writer2 := new_size(writer, 8192)

		if writer.wr is bytebuf.Buffer && writer2.wr is bytebuf.Buffer {
			assert writer2.wr == writer.wr
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

				mut buf := new_size(w, bs)
				assert buf.write(data[..nwrite]) ? == nwrite
				buf.flush() ?

				assert w.bytes() == data[..nwrite]
			}
		}
	}
}
