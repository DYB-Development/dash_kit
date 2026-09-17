import { createRoot } from "react-dom/client"
import "react-grid-layout/css/styles.css"
import "keystone_ui-blocks/src/block_grid.css"
import BlockGrid from "keystone_ui-blocks/src/BlockGrid.jsx"
import { register } from "keystone_ui-react/src/registry.js"
import { startMounting } from "keystone_ui-react/src/mounting.js"

register("dash_kit/dashboard-grid", BlockGrid)

startMounting(document, createRoot)
