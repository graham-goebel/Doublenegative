import React from 'react'
import { useLibraryStore } from './store/libraryStore'
import { TopBar } from './components/layout/TopBar'
import { LibraryView } from './components/library/LibraryView'
import { DevelopView } from './components/develop/DevelopView'

export function App() {
  const viewMode = useLibraryStore(s => s.viewMode)

  return (
    <div className="flex flex-col h-screen bg-[#1a1a1a] text-white overflow-hidden">
      <TopBar />
      <div className="flex flex-1 overflow-hidden">
        {viewMode === 'library' ? <LibraryView /> : <DevelopView />}
      </div>
    </div>
  )
}
