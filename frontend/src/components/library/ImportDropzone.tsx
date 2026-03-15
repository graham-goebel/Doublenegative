import React from 'react'
import { useDropzone } from 'react-dropzone'
import { useLibraryStore } from '../../store/libraryStore'

export function ImportDropzone({ children }: { children: React.ReactNode }) {
  const importFiles = useLibraryStore(s => s.importFiles)

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop: files => { if (files.length) importFiles(files) },
    noClick: true,
    accept: {
      'image/jpeg': ['.jpg', '.jpeg'],
      'image/tiff': ['.tif', '.tiff'],
      'image/png': ['.png'],
      'image/x-canon-cr2': ['.cr2'],
      'image/x-nikon-nef': ['.nef'],
      'image/x-sony-arw': ['.arw'],
      'image/x-adobe-dng': ['.dng'],
      'image/x-fuji-raf': ['.raf'],
      'image/x-olympus-orf': ['.orf'],
      'image/x-panasonic-rw2': ['.rw2'],
    },
  })

  return (
    <div {...getRootProps()} className="relative flex-1 overflow-hidden">
      <input {...getInputProps()} />
      {isDragActive && (
        <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/70 border-2 border-dashed border-accent rounded">
          <p className="text-accent text-xl font-medium">Drop images to import</p>
        </div>
      )}
      {children}
    </div>
  )
}
