!
!  Written by Leandro Martínez, 2009-2011.
!  Copyright (c) 2009-2018, Leandro Martínez, Jose Mario Martinez,
!  Ernesto G. Birgin.
!
! Subroutine that computes the function value
!

subroutine computef(n,x,f)

   use sizes
   use compute_data
   use input, only : fix
   use pbc
   implicit none

   integer :: n, i, j, k, ibox
   integer :: ilugan, ilubar, icart, itype, imol, iatom, idatom, &
      iboxx, iboxy, iboxz

   double precision :: v1(3), v2(3), v3(3)
   double precision :: x(n)
   double precision :: f,fparc,fplus
   double precision :: xbar, ybar, zbar
   double precision :: beta, gama, teta

   ! Reset function value

   f = 0.d0
   frest = 0.d0
   fdist = 0.d0

   ! Reset boxes

   if(.not.init1) call resetboxes()

   ! Transform baricenter and angles into cartesian coordinates
   ! Computes cartesian coordinates from vector x and coor

   ilubar = 0
   ilugan = ntotmol*3
   icart = 0

   do itype = 1, ntype
      if(.not.comptype(itype)) then
         icart = icart + nmols(itype)*natoms(itype)
      else
         do imol = 1, nmols(itype)

            xbar = x(ilubar+1)
            ybar = x(ilubar+2)
            zbar = x(ilubar+3)

            ! Computing the rotation matrix

            beta = x(ilugan+1)
            gama = x(ilugan+2)
            teta = x(ilugan+3)

            call eulerrmat(beta,gama,teta,v1,v2,v3)

            ! Looping over the atoms of this molecule

            idatom = idfirst(itype) - 1
            do iatom = 1, natoms(itype)

               icart = icart + 1
               idatom = idatom + 1

               ! Computing the cartesian coordinates for this atom

               call compcart(icart,xbar,ybar,zbar, &
                  coor(idatom,1),coor(idatom,2),coor(idatom,3), &
                  v1,v2,v3)

               ! Adding to f the value relative to constraints for this atom

               call comprest(icart,fplus)
               f = f + fplus
               frest = dmax1(frest,fplus)
               if(move) frest_atom(icart) = frest_atom(icart) + fplus

               ! Putting atoms in their boxes

               if(.not.init1) then

                  !
                  call setibox(xcart(icart,1), xcart(icart,2), xcart(icart,3), &
                     sizemin, boxl, nboxes, iboxx, iboxy, iboxz)

                  ! Atom linked list

                  latomnext(icart) = latomfirst(iboxx,iboxy,iboxz)
                  latomfirst(iboxx,iboxy,iboxz) = icart

                  ! Box with atoms linked list

                  if ( .not. hasfree(iboxx,iboxy,iboxz) ) then
                     hasfree(iboxx,iboxy,iboxz) = .true.
                     call ijk_to_ibox(iboxx,iboxy,iboxz,ibox)
                     lboxnext(ibox) = lboxfirst
                     lboxfirst = ibox

                     ! Add boxes with fixed atoms which are vicinal to this box, and
                     ! are behind

                     if ( fix ) then
                        call add_box_behind(idx_box(iboxx-1, nboxes(1)),iboxy,iboxz)
                        call add_box_behind(iboxx,idx_box(iboxy-1, nboxes(2)),iboxz)
                        call add_box_behind(iboxx,iboxy,idx_box(iboxz-1, nboxes(3)))

                        call add_box_behind(iboxx,idx_box(iboxy-1,nboxes(2)),idx_box(iboxz+1,nboxes(3)))
                        call add_box_behind(iboxx,idx_box(iboxy-1,nboxes(2)),idx_box(iboxz-1,nboxes(3)))
                        call add_box_behind(idx_box(iboxx-1,nboxes(1)),idx_box(iboxy+1,nboxes(2)),iboxz)
                        call add_box_behind(idx_box(iboxx-1,nboxes(1)),iboxy,idx_box(iboxz+1,nboxes(3)))
                        call add_box_behind(idx_box(iboxx-1,nboxes(1)),idx_box(iboxy-1,nboxes(2)),iboxz)
                        call add_box_behind(idx_box(iboxx-1,nboxes(1)),iboxy,idx_box(iboxz-1,nboxes(3)))

                        call add_box_behind(idx_box(iboxx-1,nboxes(1)),idx_box(iboxy+1,nboxes(2)),idx_box(iboxz+1,nboxes(3)))
                        call add_box_behind(idx_box(iboxx-1,nboxes(1)),idx_box(iboxy+1,nboxes(2)),idx_box(iboxz-1,nboxes(3)))
                        call add_box_behind(idx_box(iboxx-1,nboxes(1)),idx_box(iboxy-1,nboxes(2)),idx_box(iboxz+1,nboxes(3)))
                        call add_box_behind(idx_box(iboxx-1,nboxes(1)),idx_box(iboxy-1,nboxes(2)),idx_box(iboxz-1,nboxes(3)))
                     end if

                  end if

                  ibtype(icart) = itype
                  ibmol(icart) = imol

               end if

            end do

            ilugan = ilugan + 3
            ilubar = ilubar + 3

         end do
      end if
   end do

   if(init1) return

   ! Minimum distance function evaluation

   ibox = lboxfirst
   do while( ibox > 0 )

      call ibox_to_ijk(ibox,i,j,k)

      icart = latomfirst(i,j,k)
      do while( icart > 0 )

         if(comptype(ibtype(icart))) then
            ! Interactions inside box
            f = f + fparc(icart,latomnext(icart))
            ! Interactions of boxes that share faces
            f = f + fparc(icart,latomfirst(idx_box(i+1, nboxes(1)),j,k))
            f = f + fparc(icart,latomfirst(i,idx_box(j+1, nboxes(2)),k))
            f = f + fparc(icart,latomfirst(i,j,idx_box(k+1, nboxes(3))))
            ! Interactions of boxes that share axes
            f = f + fparc(icart,latomfirst(idx_box(i+1, nboxes(1)),idx_box(j+1, nboxes(2)),k))
            f = f + fparc(icart,latomfirst(idx_box(i+1, nboxes(1)),j,idx_box(k+1, nboxes(3))))
            f = f + fparc(icart,latomfirst(idx_box(i+1, nboxes(1)),idx_box(j-1, nboxes(2)),k))
            f = f + fparc(icart,latomfirst(idx_box(i+1, nboxes(1)),j,idx_box(k-1, nboxes(3))))
            f = f + fparc(icart,latomfirst(i,idx_box(j+1, nboxes(2)),idx_box(k+1, nboxes(3))))
            f = f + fparc(icart,latomfirst(i,idx_box(j+1, nboxes(2)),idx_box(k-1, nboxes(3))))
            ! Interactions of boxes that share vertices
            f = f + fparc(icart,latomfirst(idx_box(i+1, nboxes(1)),idx_box(j+1, nboxes(2)),idx_box(k+1, nboxes(3))))
            f = f + fparc(icart,latomfirst(idx_box(i+1, nboxes(1)),idx_box(j+1, nboxes(2)),idx_box(k-1, nboxes(3))))
            f = f + fparc(icart,latomfirst(idx_box(i+1, nboxes(1)),idx_box(j-1, nboxes(2)),idx_box(k+1, nboxes(3))))
            f = f + fparc(icart,latomfirst(idx_box(i+1, nboxes(1)),idx_box(j-1, nboxes(2)),idx_box(k-1, nboxes(3))))
         end if

         icart = latomnext(icart)
      end do

      ibox = lboxnext(ibox)
   end do

   return
end subroutine computef

subroutine add_box_behind(i,j,k)

   use sizes
   use compute_data
   implicit none
   integer :: ibox, i, j, k

   if ( .not. hasfree(i,j,k) .and. latomfix(i,j,k) /= 0 ) then
      hasfree(i,j,k) = .true.
      call ijk_to_ibox(i,j,k,ibox)
      lboxnext(ibox) = lboxfirst
      lboxfirst = ibox
   end if

end subroutine add_box_behind

