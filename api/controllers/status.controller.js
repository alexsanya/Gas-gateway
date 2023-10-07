import statusService from "../services/statusService.service.js";

function getStatus() {
  return {
    isFree: statusService.getIsFree(),
    lastTransaction: statusService.getLastHash()
  }
}

export default {
  getStatus
}
