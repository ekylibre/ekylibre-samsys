(function (E) {
    class RideGroups {
        constructor(element) {
            this.list = element;
            this.listSelectorInputs = element.querySelectorAll('input[data-list-selector]');
            this.interventionRequestBtn = element.parentElement.querySelector('#new-intervention-rides');
            this.interventionRecordBtn = element.parentElement.querySelector('#new-intervention-rides');
            this.interventionRequestUrl = this.interventionRequestBtn.href;
            this.interventionRecordUrl = this.interventionRecordBtn.href;
        }

        init() {
            this.listSelectorInputs.forEach((input) => {
                input.addEventListener('change', () => {
                    const selectedIds = this.selectedIds;
                    this.handleBtnsDisabling(selectedIds);
                    this.updateBtnsHref(selectedIds);
                });
            });
        }

        handleBtnsDisabling(ids) {
            const disabled = !ids.length;
            this.interventionRequestBtn.classList.toggle('disabled', !!disabled);
            this.interventionRecordBtn.classList.toggle('disabled', !!disabled);
        }

        updateBtnsHref(ids) {
            const url = new URL(this.interventionRequestUrl);
            if (ids.length > 0) {
                ids.map((id) => url.searchParams.append('ride_ids[]', id));
            }
            this.interventionRequestBtn.setAttribute('href', url);
            this.interventionRecordBtn.setAttribute('href', url);
        }

        get selectedIds() {
            return [...this.listSelectorInputs]
                .filter((input) => input.checked && input.dataset.listSelector != 'all')
                .map((input) => input.dataset.listSelector);
        }
    }

    let disabledRideAffectedSelector = function() {
        const rideAffected = document.querySelectorAll('.affected > .list-selector > input')
        rideAffected.forEach(function(ride) {
            ride.setAttribute("disabled", true)
        })
    };

    let addColorOnRidesList = function(name, color) {
        let title = document.querySelector(`[title=${name}]`);
        title.style.cssText = 'display: flex; align-items: center;'
        let html = `<div style='background-color: ${color}; height: 10px; width: 10px; border-radius: 50px; margin-right: 7px;'></div>`
        title.insertAdjacentHTML('afterbegin', html)
    }

    let loadRidesColorAfterMap = function() {
        const map = $("[data-visualization]").visualization('instance').map
        map.on('async-layers-loaded', function(){
            const getValuesofTargets = Object.values(map._targets)
            const getRides = getValuesofTargets.filter(target => target.options.rideSet == true)
            const ridesData = getRides.map((ride) => { return {name: ride.options.label, color: ride.options.color[0]} } )

            ridesData.forEach(function(ride){
                addColorOnRidesList(ride.name, ride.color);
            })
        })
    }

    let reloadRidesColorAfterClicOnActiveList = function() {
        $(document).on('list:page:change', function(){  
            disabledRideAffectedSelector();
        
            const ridesNumber = []
            const rideList = document.querySelector('#rides-list')
            const ridesTitle = rideList.querySelectorAll('[id] > td.ride-title')
            ridesTitle.forEach(function(ride) {ridesNumber.push(ride.title)})

            ridesNumber.forEach(function(ride) {
                let setLegendRideNameId = `legend-${ride.toLowerCase()}`
                let legendRideId = document.querySelector(`#${setLegendRideNameId}`);
                let rideLengendColor = legendRideId.querySelector('.leaflet-categories-sample').style.backgroundColor

                addColorOnRidesList(ride, rideLengendColor);
            })
        })
    }

    E.onDomReady(function () {
        const element = document.querySelector('#rides-list');
        if (element !== null) {
            new RideGroups(element).init();
            disabledRideAffectedSelector();
            loadRidesColorAfterMap();
            reloadRidesColorAfterClicOnActiveList();
        }
    });
})(ekylibre);